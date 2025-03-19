#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : skl2-onnx
# Version        : 1.18.0
# Source repo    : https://github.com/onnx/sklearn-onnx.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=sklearn-onnx
PACKAGE_VERSION=${1:-v1.18}
PACKAGE_URL=https://github.com/onnx/sklearn-onnx.git
PACKAGE_DIR=sklearn-onnx

# Install necessary system packages
yum install -y git  gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran make wget \
    python3.12 python3.12-devel python3.12-pip \
    openblas-devel bzip2-devel libffi-devel zlib-devel cmake ninja-build patch 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Install required Python packages
pip3.12 install numpy==2.0.2 scikit-learn==1.6.1 scipy==1.15.2 pandas pybind11 pytest cmake flatbuffers wheel lightgbm 

echo "Cloning and installing onnxruntime..."
git clone https://github.com/microsoft/onnxruntime
cd onnxruntime
git checkout d1fb58b0f2be7a8541bfa73f8cbb6b9eba05fb6b
# Build the onnxruntime package and create the wheel
echo "Building onnxruntime..."
sed -i 's/python3/python3.12/g' build.sh
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
cd ..
rm -rf onnxruntime

#cloning and installing protobuf and updating version using sed command
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

#cloning and installing onnxconverter-common
git clone https://github.com/microsoft/onnxconverter-common
cd onnxconverter-common
git checkout v1.14.0
sed -i 's/\bprotobuf==[^ ]*\b/protobuf==4.25.3/g' pyproject.toml
sed -i 's/\"onnx\"/\"onnx==1.17.0\"/' pyproject.toml
sed -i 's/\"numpy\"/\"numpy==2.0.2\"/' pyproject.toml
sed -i "/tool.setuptools.dynamic/d" pyproject.toml
sed -i "/onnxconverter_common.__version__/d" pyproject.toml
sed -i 's/\"numpy\"/\"numpy==2.0.2\"/' requirements.txt
sed -i 's/\bprotobuf==[^ ]*\b/protobuf==4.25.3/g' requirements.txt
python3.12 setup.py install
cd ..
# Clean up the onnxruntime repository
rm -rf onnxconverter-common

pip3.12 install onnxmltools protobuf==4.25.3 onnx==1.17.0 
# Clone the package from the repository
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
# Build skl2onnx
if ! pip3.12 install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# # Run tests
echo "Running tests for $PACKAGE_NAME..."
cd tests
# Test the onnxconverter-common package
#skipping below test cases because of KeyError: 'schemas'
if ! pytest --ignore=test_sklearn_power_transformer.py --ignore=test_sklearn_feature_hasher.py --ignore=test_sklearn_adaboost_converter.py --ignore=test_algebra_onnx_doc.py; then
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
