#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : jaxlib
# Version          : jaxlib-v0.4.7
# Source repo      : https://github.com/jax-ml/jax
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
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


# Variables
PACKAGE_NAME=jax
PACKAGE_VERSION=${1:-jaxlib-v0.4.7}
PACKAGE_URL=https://github.com/jax-ml/jax
CURRENT_DIR=$pwd

# Install dependencies
echo "Installing dependencies -------------------------------------------------------------"
yum install -y python-devel python-pip git gcc gcc-c++ make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel  libjpeg-devel 

echo "Installing dependencies -------------------------------------------------------------"
yum install -y zlib-devel freetype-devel procps-ng openblas-devel meson ninja-build gcc-gfortran  libomp-devel zip unzip sqlite-devel  

echo "Installing dependencies -------------------------------------------------------------"
yum install -y java-11-openjdk-devel  libtool xz  libevent-devel  clang java-11-openjdk java-11-openjdk-headless zip openblas


export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib64/:$LD_LIBRARY_PATH
 
# dnf groupinstall -y "Development Tools"
 
#installing bazel from source
echo "Installing bazel -------------------------------------------------------------"
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/5.1.1/bazel-5.1.1-dist.zip
unzip bazel-5.1.1-dist.zip
echo "Installing bazel -------------------------------------------------------------"
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
cp output/bazel /usr/local/bin
export PATH=/usr/local/bin:$PATH
bazel --version
cd ..
 
echo "Installing dependencies via pip3-------------------------------------------------------------"
pip3 install numpy==1.26.4 scipy wheel pytest
pip3 install numpy==1.26.4 opt-einsum==3.3.0  ml-dtypes==0.5.0 absl-py 
 
# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Add boringssl to build for jaxlib
BORINGSSL_SUPPORT_CONTENT=$(cat << EOF
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive") 
http_archive( 
    name = "boringssl",
    sha256 = "534fa658bd845fd974b50b10f444d392dfd0d93768c4a51b61263fd37d851c40",
    strip_prefix = "boringssl-b9232f9e27e5668bc0414879dcdedb2a59ea75f2", 
    urls = [ 
        "https://github.com/google/boringssl/archive/b9232f9e27e5668bc0414879dcdedb2a59ea75f2.tar.gz", 
    ], 
)
EOF
)
echo "$BORINGSSL_SUPPORT_CONTENT" > WORKSPACE-TEMP
cat WORKSPACE >> WORKSPACE-TEMP 
rm -rf WORKSPACE && mv WORKSPACE-TEMP WORKSPACE
 
cd build
#Install
echo "Building package-------------------------------------------------------------"
if ! (python3 build.py ) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
echo "Package build successful-------------------------------------------------------------"

cp dist/*.whl $CURRENT_DIR/
 
# Run test cases
#skipping test part as jaxlib don't have tests to execute
#if !(pytest); then
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
