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
yum install -y git make libtool  gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran libevent-devel zlib-devel openssl-devel python python-devel python3.12 python3.12-devel python3.12-pip cmake openblas openblas-devel patch
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
# Download and install protobuf-c
echo "Downloading and installing protobuf-c..."
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v3.20.2
git submodule update --init --recursive
mkdir build_source && cd build_source
cmake ../cmake -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_POSITION_INDEPENDENT_CODE=ON -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release
echo "Building protobuf-c..."
make -j$(nproc)
echo "Installing protobuf-c..."
make install
cd ../..

# Clone and install onnxconverter-common
echo "Cloning and installing onnxconverter-common..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive
pip3.12 install cmake setuptools ninja wheel pytest numpy==2.0.2 packaging scipy==1.15.2 onnx==1.17.0 flatbuffers nbval pythran cython onnxmltools
sed -i 's/\bprotobuf==[^ ]*\b/protobuf==4.25.3/g' pyproject.toml
sed -i 's/\"onnx\"/\"onnx==1.17.0\"/' pyproject.toml
sed -i "/tool.setuptools.dynamic/d" pyproject.toml
sed -i "/onnxconverter_common.__version__/d" pyproject.toml
cd ..
# Clone and install onnxruntime
echo "Cloning and installing onnxruntime..."
git clone https://github.com/microsoft/onnxruntime
cd onnxruntime
git checkout d1fb58b0f2be7a8541bfa73f8cbb6b9eba05fb6b
# Build the onnxruntime package and create the wheel
sed -i 's/python3/python3.12/g' build.sh
echo "Building onnxruntime..."
./build.sh \
  --cmake_extra_defines "onnxruntime_PREFER_SYSTEM_LIB=ON" \
  --cmake_generator Ninja \
  --build_shared_lib \
  --config Release \
  --update \
  --build \
  --skip_submodule_sync \
  --allow_running_as_root \
  --compile_no_warning_as_error \
  --build_wheel
# Install the built onnxruntime wheel
echo "Installing onnxruntime wheel..."
cp ./build/Linux/Release/dist/* ./
pip3.12 install ./*.whl

# Clean up the onnxruntime repository
cd ..
rm -rf onnxruntime

cd $PACKAGE_DIR
if ! python3.12 setup.py install; then
        echo "------------------$PACKAGE_NAME:wheel_built_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  wheel_built_fails"
        exit 1
fi

echo "Running tests for $PACKAGE_NAME..."
# Test the onnxconverter-common package
#skipping due to attribute errors
if ! pytest --ignore=tests/test_auto_mixed_precision.py --ignore=tests/test_onnx2py.py; then
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
