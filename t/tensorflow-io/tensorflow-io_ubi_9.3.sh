#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : io
# Version          : v0.35.0
# Source repo      : https://github.com/tensorflow/io.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

set -e

# Variables
# Variables
PACKAGE_NAME=io
PACKAGE_VERSION=${1:-v0.35.0}
PACKAGE_URL=https://github.com/tensorflow/io.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=io
PYTHON_VER=${2:-3.11}

yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install dependencies
yum install -y python${PYTHON_VER} python${PYTHON_VER}-devel python${PYTHON_VER}-pip wget git unzip tar zip vim pkgconfig hdf5 hdf5-devel gcc gcc-c++ libcurl-devel libffi-devel blas lapack lapack-devel gfortran openblas openblas-devel patchelf cmake openssl-devel  sqlite-devel make cmake bzip2-devel zlib-devel libjpeg-devel freetype-devel procps-ng epel-release meson ninja-build gcc-gfortran libomp-devel

yum install -y libxcrypt-compat libtirpc-devel

python${PYTHON_VER} -m pip install --upgrade pip

ln -sf $CURRENT_DIR/usr/bin/python${PYTHON_VER} /usr/bin/python3
ln -sf $CURRENT_DIR/usr/bin/python${PYTHON_VER} /usr/bin/python

dnf groupinstall -y "Development Tools"

export LD_LIBRARY_PATH=/usr/lib64/:$LD_LIBRARY_PATH
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true

#install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust

#Install the dependencies
echo "------------------------Installing dependencies-------------------"
yum install -y  autoconf automake libtool curl-devel swig atlas-devel patch 

#Set JAVA_HOME
yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.25.0.9-3.el9.ppc64le
export PATH=$JAVA_HOME/bin:$PATH

#installing bazel from source
mkdir bazel
cd  bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.1.0/bazel-6.1.0-dist.zip
unzip bazel-6.1.0-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
echo "------------------------------Installed bazel version------------------------------"
bazel --version
cd ..


#Build tensorflow-io
echo "------------------------Cloning tensorflow-io-------------------"
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install build wheel setuptools
python setup.py -q bdist_wheel --project tensorflow_io_gcs_filesystem
cd dist
pip install tensorflow_io_gcs_filesystem-*-linux_ppc64le.whl
cd ..

#Build tensorflow
echo "------------------------Cloning tensorflow-------------------"
cd $CURRENT_DIR
git clone https://github.com/tensorflow/tensorflow
cd  tensorflow
git checkout v2.14.1

echo "------------------------Exporting variable-------------------"
cpu_model=$(lscpu | grep "Model name:" | awk -F: '{print $2}' | tr '[:upper:]' '[:lower:]' | cut -d '(' -f1 | cut -d ',' -f1)

export CC_OPT_FLAGS="-mcpu=${cpu_model} -mtune=${cpu_model}"
export TF_PYTHON_VERSION=$(python --version | awk '{print $2}' | cut -d. -f1,2)
export HERMETIC_PYTHON_VERSION=$(python --version | awk '{print $2}' | cut -d. -f1,2)
export PYTHON_BIN_PATH=/usr/bin/python
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

bazel build -s //tensorflow/tools/pip_package:build_pip_package --local_ram_resources=8192 --local_cpu_resources=8 --jobs=8 --config=opt

echo "Bazel build successful ---------------------------------------------------------------------------------------------"

#building the wheel 
bazel-bin/tensorflow/tools/pip_package/build_pip_package $CURRENT_DIR

echo "Build wheel ---------------------------------------------------------------------------------------------"

cd $CURRENT_DIR

pip install tensorflow-2.14.1-cp311-cp311-linux_ppc64le.whl 

echo "Wheel installed succesfuly ---------------------------------------------------------------------------------------------"

python -c "import tensorflow as tf; print(tf.__version__)"
export TF_HEADER_DIR=$(python -c "import tensorflow as tf; print(tf.sysconfig.get_include())")
export TF_SHARED_LIBRARY_DIR=$(python -c "import tensorflow as tf; print(tf.sysconfig.get_lib())")
export TF_SHARED_LIBRARY_NAME="libtensorflow_framework.so.2"

cd $CURRENT_DIR/io
pip install grpcio-tools==1.56.2 --no-cache-dir
pip install .


export PYTHON_BIN_PATH="$PYTHON"
export PYTHON_LIB_PATH="$SP_DIR"
export PYTHON_PATH="$PYTHON"
export TF_PYTHON_VERSION=$(python --version | awk '{print $2}' | cut -d. -f1,2)
export TF_HEADER_DIR=$(python -c "import tensorflow as tf; print(tf.sysconfig.get_include())")
export TF_SHARED_LIBRARY_DIR=$(python -c "import tensorflow as tf; print(tf.sysconfig.get_lib())")
export TF_SHARED_LIBRARY_NAME="libtensorflow_framework.so.2"
export PYTHON_BIN_PATH="$PYTHON"
export PYTHON_LIB_PATH="$SP_DIR"
export PYTHON_PATH="$PYTHON"
export CXXFLAGS="-std=c++17 -fvisibility=hidden -D_GLIBCXX_USE_CXX11_ABI=1 -DEIGEN_MAX_ALIGN_BYTES=64 -Wno-maybe-uninitialized"
export BAZEL_OPTIMIZATION="--config=optimization"
export TF_USE_MODULAR_FILESYSTEM=1

# Define the file path
BAZELRC_FILE="tf_io.bazelrc"

# Create the file and write the content
cat > "$BAZELRC_FILE" <<EOL
# Optimization flags
build:optimization --copt="-mcpu=${cpu_model}"
build:optimization --copt="-mtune=${cpu_model}"
#build:optimization --copt="-march=${cpu_model}"

# General build flags
build --copt="-fvisibility=hidden"
build --copt="-D_GLIBCXX_USE_CXX11_ABI=1"
build --copt="-DEIGEN_MAX_ALIGN_BYTES=64"
build --copt="-Wno-maybe-uninitialized"
build --cxxopt="-std=c++17"

# Ensure C++17 is used globally for all builds and external repositories
build --host_cxxopt="-std=c++17"
build --repo_env=CC="gcc"
build --repo_env=CXX="g++ -std=c++17"
build --action_env=CXXFLAGS="-std=c++17"
build --action_env=CXX="g++ -std=c++17"

# TensorFlow shared library name
build --action_env TF_SHARED_LIBRARY_NAME="libtensorflow_framework.so.2"

# Experimental flags and platform-specific configurations
build --experimental_repo_remote_exec
build --enable_platform_specific_config

# Optimization mode
build:optimization --compilation_mode=opt

# Build verbosity and debugging options
build --noshow_progress
build --noshow_loading_progress
build --verbose_failures
build --test_output=errors
build --experimental_ui_max_stdouterr_bytes=-1
# Enforce consistent C++ version for external dependencies
build --crosstool_top=@bazel_tools//tools/cpp:toolchain
build --extra_toolchains=@bazel_tools//tools/cpp:all
build --incompatible_enable_cc_toolchain_resolution
EOL

echo "tf_io.bazelrc file has been created successfully."

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/t/tensorflow-io-gcs-filesystem/tf-io-gcs-filesystem.patch
git apply /tf-io-gcs-filesystem.patch

echo "---------------------------------Building the package--------------------------------------------"
#Install
if ! (bazel build --experimental_repo_remote_exec --cxxopt="-std=c++17" --host_cxxopt="-std=c++17" --repo_env=CXX="g++ -std=c++17" //tensorflow_io/... //tensorflow_io_gcs_filesystem/...) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "-----------------------Building tf-text wheel ----------------------------"
python setup.py bdist_wheel --data bazel-bin

# Run tests for the pip_package directory
if ! (bazel test //tensorflow_io/...); then
    # Check if the failure is specifically due to "No test targets were found"
    if bazel test //tensorflow_io/... 2>&1 | grep -q "No test targets were found"; then
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

