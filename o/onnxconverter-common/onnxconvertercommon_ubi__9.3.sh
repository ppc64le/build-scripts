#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnxconverter-common
# Version          : v1.14.0
# Source repo      : https://github.com/microsoft/onnxconverter-common
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=onnxconverter-common
PACKAGE_VERSION=${1:-v1.14.0}
PACKAGE_URL=https://github.com/microsoft/onnxconverter-common
PACKAGE_DIR=onnxconverter-common

echo "Installing dependencies..."
yum install -y git make libtool gcc-toolset-13  gcc-c++ libevent-devel zlib-devel openssl-devel python python-devel cmake gcc-gfortran openblas openblas-devel

echo "Downloading and installing protobuf-c"
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v3.20.2
git submodule update --init --recursive
mkdir build_source && cd build_source
cmake ../cmake -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_POSITION_INDEPENDENT_CODE=ON -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release
echo "Building..."
make -j$(nproc)
echo "Installing..."
make install
cd ../..

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

pip install cmake setuptools ninja wheel pytest
pip install numpy==1.24.3 onnx==1.17.0 nbval pythran scipy cython

sed -i 's/\bprotobuf==[^ ]*\b/protobuf==4.25.3/g' pyproject.toml
sed -i 's/\"onnx\"/\"onnx==1.17.0\"/' pyproject.toml
sed -i "s/version=version_str/version=version_str+'+opence'/g" setup.py
sed -i "/tool.setuptools.dynamic/d" pyproject.toml
sed -i "/onnxconverter_common.__version__/d" pyproject.toml

if ! python3 setup.py install; then
        echo "------------------$PACKAGE_NAME:wheel_built_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  wheel_built_fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:wheel_built_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Wheel_built_success"
        exit 0
fi

echo "Running tests for $PACKAGE_NAME..."
# Test the package
if ! python3 -c "import onnxconverter_common"; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
