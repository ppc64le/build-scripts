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
yum install -y git gcc-toolset-13 gcc-c++ gfortran make wget \
    python3 python3-devel python3-pip \
    openblas-devel bzip2-devel libffi-devel zlib-devel cmake ninja-build patch

# Install required Python packages
pip3 install numpy protobuf scipy scikit-learn pandas pytest onnx cmake flatbuffers wheel lightgbm onnxmltools onnxconverter-common

# Clone the package from the repository
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build skl2onnx
echo "$PACKAGE_NAME build starts!!"
sed -i 's/onnx>=1.2.1//g' requirements.txt
sed -i 's/onnxconverter-common>=1.7.0//g' requirements.txt
sed -i "s/version=version_str/version=version_str+'+opence'/g" setup.py

sed -i 's/scikit-learn>=1\.1/scikit-learn==1.5.2/' requirements.txt   #pinning scikit_learn
cd ..

echo "Cloning and installing onnxruntime..."
git clone https://github.com/microsoft/onnxruntime
cd onnxruntime
git checkout d1fb58b0f2be7a8541bfa73f8cbb6b9eba05fb6b
# Build the onnxruntime package and create the wheel
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
pip3 install ./*.whl

# Clean up the onnxruntime repository
cd ..
rm -rf onnxruntime

cd $PACKAGE_DIR
if ! pip3 install -e . ; then
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
if ! pytest --ignore=test_sklearn_power_transformer.py --ignore=test_sklearn_feature_hasher.py --ignore=test_algebra_onnx_doc.py; then
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
