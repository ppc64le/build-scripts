#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tensorflow-text
# Version       : 2.14.0
# Source repo   : https://github.com/tensorflow/text.git
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
PACKAGE_NAME=text
PACKAGE_VERSION=${1:-v2.14.0}
PACKAGE_URL=https://github.com/tensorflow/text.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=text/oss_scripts/pip_package

yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install dependencies
yum install -y gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-libstdc++-devel
export PATH=/opt/rh/gcc-toolset-12/root/usr/bin:$PATH

yum install -y python python-devel python-pip git make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel  libjpeg-devel zlib-devel freetype-devel procps-ng openblas-devel epel-release meson ninja-build gcc-gfortran  libomp-devel zip unzip sqlite-devel sqlite libnsl libarrow libarrow-python-devel


yum install -y libxcrypt libxcrypt-compat rsync
python -m pip install --upgrade pip
python -m pip install --upgrade setuptools wheel build


echo "------------------------Installing dependencies-------------------"
dnf groupinstall -y "Development Tools"

#Install the dependencies
echo "------------------------Installing dependencies-------------------"
yum install -y  autoconf automake libtool curl-devel swig hdf5-devel atlas-devel patch patchelf

#Set JAVA_HOME
echo "------------------------Installing java-------------------"
yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH


# Build Bazel dependency
echo "------------------------Installing bazel-------------------"
cd $CURRENT_DIR
mkdir -p /bazel
cd /bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.1.0/bazel-6.1.0-dist.zip
unzip bazel-6.1.0-dist.zip
echo "------------------------Installing bazel-------------------"
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version
cd $CURRENT_DIR

# Install six.
echo "------------------------Installing dependencies-------------------"
pip install --upgrade absl-py
pip install --upgrade six==1.16.0
pip install "numpy<2" wheel==0.38.4 werkzeug
pip install "urllib3<1.27,>=1.21.1" requests
pip install "protobuf<=4.25.2"
pip install tensorflow-datasets


# Install numpy, scipy and scikit-learn required by the builds
ln -s /usr/include/locale.h /usr/include/xlocale.h

export LD_LIBRARY_PATH=/usr/lib64/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-12/root/usr/lib64:$LD_LIBRARY_PATH
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true


#Build tensorflow-io-gcs-filesystem
echo "------------------------Cloning tensorflow-io-------------------"
cd $CURRENT_DIR
git clone https://github.com/tensorflow/io.git
cd io
git checkout v0.35.0

echo "------------------------Generating wheel-------------------"
pip install --upgrade pip wheel
python setup.py -q bdist_wheel --project tensorflow_io_gcs_filesystem
cd dist
pip install tensorflow_io_gcs_filesystem-*-linux_ppc64le.whl


#Build tensorflow
echo "------------------------Cloning tensorflow-------------------"
cd $CURRENT_DIR
git clone https://github.com/tensorflow/tensorflow
cd  tensorflow
git checkout v2.14.1

echo "------------------------Exporting variable-------------------"
cpu_model=$(lscpu | grep "Model name:" | awk -F: '{print $2}' | tr '[:upper:]' '[:lower:]' | cut -d '(' -f1 | cut -d ',' -f1 | xargs)
export CC_OPT_FLAGS="-mcpu=${cpu_model} -mtune=${cpu_model}"
echo "CC_OPT_FLAGS set to: ${CC_OPT_FLAGS}"

export CC_OPT_FLAGS="-mcpu=${cpu_model} -mtune=${cpu_model}"
export TF_PYTHON_VERSION=$(python --version | awk '{print $2}' | cut -d. -f1,2)
export HERMETIC_PYTHON_VERSION=$(python --version | awk '{print $2}' | cut -d. -f1,2)
export PYTHON_BIN_PATH=$(which python)
export GCC_HOST_COMPILER_PATH=$(which gcc)
export CC=$GCC_HOST_COMPILER_PATH
export PYTHON=/root/tensorflow/tfenv/bin/python
export SP_DIR=/root/tensorflow/tfenv/lib/python$(python --version | awk '{print $2}' | cut -d. -f1,2)/site-packages/
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_NEED_JEMALLOC=1
export TF_ENABLE_XLA=1
export TF_NEED_OPENCL=0
export TF_NEED_CUDA=0
export TF_NEED_MKL=0
export TF_NEED_VERBS=0
export TF_NEED_MPI=0
export TF_CUDA_CLANG=0
export TFCI_WHL_NUMPY_VERSION=1
export CXXFLAGS="$(echo ${CXXFLAGS} | sed -e 's/ -fno-plt//')"
export CFLAGS="$(echo ${CFLAGS} | sed -e 's/ -fno-plt//')"


# Apply the patch
echo "------------------------Applying patch-------------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/t/tensorflow/tf_2.14.1_fix.patch
git apply tf_2.14.1_fix.patch
echo "-----------------------Applied patch successfully---------------------------------------"

yes n | ./configure

echo "------------------------Bazel query-------------------"
bazel query "//tensorflow/tools/pip_package:*"

echo "Bazel query successful ---------------------------------------------------------------------------------------------"
bazel build -s //tensorflow/tools/pip_package:build_pip_package --config=opt

echo "Bazel build successful ---------------------------------------------------------------------------------------------"

#building the wheel
bazel-bin/tensorflow/tools/pip_package/build_pip_package $CURRENT_DIR

echo "Build wheel ---------------------------------------------------------------------------------------------"

cd $CURRENT_DIR

pip install tensorflow-2.14.1-*-linux_ppc64le.whl

echo "Wheel installed succesfuly ---------------------------------------------------------------------------------------------"

python -c "import tensorflow as tf; print(tf.__version__)"
export TF_HEADER_DIR=$(python -c "import tensorflow as tf; print(tf.sysconfig.get_include())")
export TF_SHARED_LIBRARY_DIR=$(python -c "import tensorflow as tf; print(tf.sysconfig.get_lib())")
export TF_SHARED_LIBRARY_NAME="libtensorflow_framework.so.2"

export BAZEL_CXXOPTS="-std=c++17"
export BAZEL_CXXFLAGS="-std=c++17"
export CC=/opt/rh/gcc-toolset-12/root/usr/bin/gcc
export CXX=/opt/rh/gcc-toolset-12/root/usr/bin/g++

#Build tensorflow-text
echo "------------------------Cloning tensorflow-text-------------------"
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd $CURRENT_DIR/$PACKAGE_DIR
pip install . --no-build-isolation
cd $CURRENT_DIR/$PACKAGE_NAME

#Install
if ! (bazel build --cxxopt='-std=c++17' --experimental_repo_remote_exec //oss_scripts/pip_package:build_pip_package) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "-----------------------Building tf-text wheel ----------------------------"
python -m pip install --upgrade wheel setuptools build
./bazel-bin/oss_scripts/pip_package/build_pip_package $CURRENT_DIR

echo "----------------Tensorflow-text wheel build successfully------------------------------------"

#skipping test part as those are in parity with x86
# Run test cases
#if ! (bazel test --test_output=errors --keep_going --experimental_repo_remote_exec tensorflow_text:all) ; then
#    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#    exit 2
#else
#    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#    exit 0
#fi

