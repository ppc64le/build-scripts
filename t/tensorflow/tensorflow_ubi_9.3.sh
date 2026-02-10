#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tensorflow
# Version       : 2.13.0
# Source repo :  https://github.com/tensorflow/tensorflow
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
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
PACKAGE_VERSION=${1:-v2.13.0}
PACKAGE_URL=https://github.com/tensorflow/tensorflow

wdir=`pwd`

#Install the dependencies
yum install -y wget zip unzip python3-devel autoconf automake libtool gcc-c++ gcc-gfortran git  freetype-devel atlas-devel  python3-pip python3 python3-devel python3-setuptools python3-wheel patch 

#Set JAVA_HOME
yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk 
export PATH=$JAVA_HOME/bin:$PATH

# Build Bazel dependency
cd $wdir
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
unzip bazel-6.5.0-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH


# Install six.
pip install --upgrade absl-py
pip install --upgrade six==1.10.0
pip install "numpy<2" "urllib3<1.27" wheel==0.29.0 werkzeug packaging patchelf
# Remove obsolete version of six, which can sometimes confuse virtualenv.
rm -rf /usr/lib/python3/dist-packages/six*

# Install numpy, scipy and scikit-learn required by the builds
ln -s /usr/include/locale.h /usr/include/xlocale.h

#Build tensorflow v2.13.0
cd $wdir
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Patching spectrogram.cc for gcc-13 compatibility..."
sed -i '1i #include <cstdint>' tensorflow/lite/kernels/internal/spectrogram.cc
echo "Patch applied."

echo "Patching cache.h for GCC-13 compatibility..."
if ! grep -q "#include <cstdint>" tensorflow/tsl/lib/io/cache.h; then
  sed -i '1i #include <cstdint>' tensorflow/tsl/lib/io/cache.h
fi
echo "Patch applied."


export CC_OPT_FLAGS="-mcpu=power8 -mtune=power8"
export GCC_HOST_COMPILER_PATH=/usr/bin/gcc
export PYTHON_BIN_PATH=$(which python)
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

echo "Using Python from virtualenv: $(which python)"
echo "Python version: $(python --version)"


yes n | ./configure

#apply patch
echo "Updating .bazelrc..."
cat <<EOF >> .bazelrc
build --define=tflite_with_xnnpack=false
build:linux --copt="-Wno-stringop-overflow"
EOF
echo ".bazelrc updated successfully!"
 
# Update tensorflow/workspace2.bzl file
echo "Updating tensorflow/workspace2.bzl..."
sed -i 's|sha256 = "9dc53f851107eaf87b391136d13b815df97ec8f76dadb487b58b2fc45e624d2c"|sha256 = "534fa658bd845fd974b50b10f444d392dfd0d93768c4a51b61263fd37d851c40"|' tensorflow/workspace2.bzl
sed -i 's|strip_prefix = "boringssl-c00d7ca810e93780bd0c8ee4eea28f4f2ea4bcdc"|strip_prefix = "boringssl-b9232f9e27e5668bc0414879dcdedb2a59ea75f2"|' tensorflow/workspace2.bzl
# sed -i '/system_build_file = \"\/\/third_party\/systemlibs:boringssl.BUILD\",/a \ \ \ \ patch_file = ["//third_party/boringssl:boringssl-for-ppc64le.patch"],' tensorflow/workspace2.bzl
sed -i 's|https://github.com/google/boringssl/archive/c00d7ca810e93780bd0c8ee4eea28f4f2ea4bcdc.tar.gz|https://github.com/google/boringssl/archive/b9232f9e27e5668bc0414879dcdedb2a59ea75f2.tar.gz|' tensorflow/workspace2.bzl
echo "tensorflow/workspace2.bzl updated successfully!"


bazel query "//tensorflow/tools/pip_package:*"
# Build TensorFlow package
if ! (bazel build --jobs=$(nproc) --config=opt //tensorflow/tools/pip_package:build_pip_package --repo_env=WHEEL_NAME=tensorflow_cpu); then
    echo "------------------$PACKAGE_NAME:Build Passed-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi
 
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
