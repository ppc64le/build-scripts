#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : triton
# Version       : v2.1.0
# Source repo   : https://github.com/triton-lang/triton.git
# Tested on     : UBI: 9.3
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=triton
PACKAGE_VERSION=${1:-v2.1.0}
PACKAGE_URL=https://github.com/triton-lang/triton.git

# Update and install required packages
echo "Updating and installing essential packages..."
dnf update -y
dnf install -y \
    python \
    python-devel \
    gcc \
    gcc-c++ \
    cmake \
    make \
    git \
    wget \
    unzip \
    tar \
    llvm \
    llvm-devel \
    llvm-static \
    llvm-libs \
    patch \
    libffi \
    libffi-devel \
    zlib \
    zlib-devel \
    ninja-build

# Install MLIR dependency
echo "Installing MLIR dependency..."
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
mkdir -p build && cd build
cmake ../llvm \
    -DLLVM_ENABLE_PROJECTS="mlir" \
    -DLLVM_BUILD_EXAMPLES=OFF \
    -DLLVM_TARGETS_TO_BUILD="PowerPC;NVPTX" \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja
ninja
ninja install
if [ $? -ne 0 ]; then
    echo "MLIR installation failed."
    exit 1
fi
cd ../..

# Set Python environment
echo "Setting up Python environment..."
pip install --upgrade pip setuptools wheel

# Clone Triton repository
echo "Cloning Triton repository..."
git clone --recursive "$PACKAGE_URL"
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install build dependencies
echo "Installing Python dependencies..."
pip install -r python/requirements.txt || echo "No requirements file found, skipping."
mkdir -p build && cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DMLIR_DIR=/usr/local/lib/cmake/mlir \
    -DCMAKE_PREFIX_PATH=/usr/local/lib/cmake/mlir

# Build Triton
echo "Building Triton..."
make -j$(nproc)

# Install Triton Python package
echo "Installing Triton Python package..."
cd ../python

# Configure Triton build
echo "Configuring Triton build..."
# Build package
if !(pip install . --no-build-isolation); then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(python -m pytest); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

