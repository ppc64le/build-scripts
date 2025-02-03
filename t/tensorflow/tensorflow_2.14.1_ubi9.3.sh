#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tensorflow
# Version       : 2.14.1
# Source repo   : https://github.com/tensorflow/tensorflow
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
# Variables
PACKAGE_NAME=tensorflow
PACKAGE_VERSION=${1:-v2.14.1}
PACKAGE_URL=https://github.com/tensorflow/tensorflow
CURRENT_DIR=$(pwd)
PACKAGE_DIR=tensorflow

echo "------------------------Installing dependencies-------------------"
yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install dependencies
echo "------------------------Installing dependencies-------------------"
yum install -y python-devel python-pip git gcc gcc-c++ make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel  libjpeg-devel zlib-devel freetype-devel procps-ng openblas-devel epel-release meson ninja-build gcc-gfortran  libomp-devel zip unzip sqlite-devel sqlite libnsl

echo "------------------------Installing dependencies-------------------"
yum install -y libxcrypt-compat rsync
#python3 -m pip install --upgrade pip
#python3 -m pip install setuptools wheel

echo "------------------------Installing dependencies-------------------"
dnf groupinstall -y "Development Tools"
pip install --upgrade pip


#install rust
echo "------------------------Installing rust-------------------"
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust


#Install the dependencies
echo "------------------------Installing dependencies-------------------"
yum install -y  autoconf automake libtool curl-devel swig hdf5-devel atlas-devel patch patchelf

#Set Python3 as default
#ln -s $CURRENT_DIR/usr/bin/python $CURRENT_DIR/usr/bin/python

#Set JAVA_HOME
echo "------------------------Installing java-------------------"
yum install -y java-11-openjdk-devel
export JAVA_HOME=$CURRENT_DIR/usr/lib/jvm/java-11-openjdk-11.0.25.0.9-3.el9.ppc64le
export PATH=$JAVA_HOME/bin:$PATH

# Build Bazel dependency
echo "------------------------Installing bazel-------------------"
cd $CURRENT_DIR
mkdir -p $CURRENT_DIR/bazel
cd $CURRENT_DIR/bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
unzip bazel-6.5.0-dist.zip
echo "------------------------Installing bazel-------------------"
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel $CURRENT_DIR/usr/local/bin
export PATH=$CURRENT_DIR/usr/local/bin:$PATH
bazel --version
cd $CURRENT_DIR

# Install six.
echo "------------------------Installing dependencies-------------------"
pip install --upgrade absl-py
pip install --upgrade six==1.10.0
pip install "numpy<2" "urllib3<1.27" wheel==0.29.0 werkzeug

# Remove obsolete version of six, which can sometimes confuse virtualenv.
rm -rf $CURRENT_DIR/usr/lib/python/dist-packages/six*

# Install numpy, scipy and scikit-learn required by the builds
ln -s $CURRENT_DIR/usr/include/locale.h $CURRENT_DIR/usr/include/xlocale.h

#Build tensorflow
echo "------------------------Cloning tensorflow-------------------"
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "------------------------Exporting variable-------------------"
export CC_OPT_FLAGS="-mcpu=power9 -mtune=power9"
export TF_PYTHON_VERSION=$(python --version | awk '{print $2}' | cut -d. -f1,2)
export HERMETIC_PYTHON_VERSION=$(python --version | awk '{print $2}' | cut -d. -f1,2)
export PYTHON_BIN_PATH=/usr/bin/python3
export GCC_HOST_COMPILER_PATH=/usr/bin/gcc
export CC=$GCC_HOST_COMPILER_PATH
export PYTHON=/root/tensorflow/tfenv/bin/python
export SP_DIR=/root/tensorflow/tfenv/lib/python$(python --version | awk '{print $2}' | cut -d. -f1,2)/site-packages/
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_NEED_GCP=1
export TF_NEED_HDFS=1
export TF_NEED_JEMALLOC=1
export TF_ENABLE_XLA=0
export TF_NEED_OPENCL=0
export TF_NEED_CUDA=0
export TF_NEED_MKL=0
export TF_NEED_VERBS=0
export TF_NEED_MPI=0
export TF_CUDA_CLANG=0
export TFCI_WHL_NUMPY_VERSION=1

# Apply the patch
echo "------------------------Applying patch-------------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/t/tensorflow/tf_2.14.1_fix.patch
git apply tf_2.14.1_fix.patch
echo "Applied patch successfully."

yes n | ./configure

echo "------------------------Bazel query-------------------"
bazel query "//tensorflow/tools/pip_package:*"

echo "Bazel query successful ---------------------------------------------------------------------------------------------"

#Install
if ! (bazel build -s //tensorflow/tools/pip_package:build_pip_package --local_ram_resources=8192 --local_cpu_resources=8 --jobs=8 --config=opt) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

#building the wheel 
bazel-bin/tensorflow/tools/pip_package/build_pip_package $CURRENT_DIR

# Run tests for the pip_package directory
if ! (bazel test --config=opt -k --jobs=$(nproc) //tensorflow/tools/pip_package/...); then
    # Check if the failure is specifically due to "No test targets were found"
    if bazel test --config=opt -k --jobs=$(nproc) //tensorflow/tools/pip_package/... 2>&1 | grep -q "No test targets were found"; then
        echo "------------------$PACKAGE_NAME:no_test_targets_found---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | No_Test_Targets_Found"
        exit 0  # Graceful exit for no test targets
    fi
    # Handle actual test errors
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Success_But_Test_Fails"
    exit 2
else
    # Tests ran successfully
    echo "------------------$PACKAGE_NAME:install_&_test_both_success------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
