#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package : pytorch
# Version : 2.1.0
# Source repo : https://github.com/pytorch/pytorch.git
# Tested on : UBI:9.3
# Language : Python
# Ci-Check : True
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
PACKAGE_NAME=pytorch
PACKAGE_VERSION=${1:-v2.1.0}
PACKAGE_URL=https://github.com/pytorch/pytorch.git
PACKAGE_DIR=pytorch
export PYTORCH_BUILD_VERSION="${PACKAGE_VERSION#v}"
export PYTORCH_BUILD_NUMBER=1
CURRENT_DIR="${PWD}"

# Install dependencies and tools
echo "Installing dependencies..."
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openblas-devel cmake gcc-gfortran

echo "Installing required Python packages..."
pip install wheel scipy ninja build pytest

echo "Installing required numpy"
pip install "numpy<2.0"

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "Rust not found. Installing Rust..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed."
fi

# Clone repository
echo "Cloning PyTorch repository...."
git clone $PACKAGE_URL
cd $PACKAGE_NAME

echo "Checking out version $PACKAGE_VERSION..."
git checkout $PACKAGE_VERSION

echo "Syncing and updating submodules..."
git submodule sync
git submodule update --init --recursive

echo "Installing package dependencies..."
pip install -r requirements.txt

export LD_LIBRARY_PATH="${CURRENT_DIR}/pytorch/torch/lib/:${LD_LIBRARY_PATH}"

# Build and install the package
echo "Starting PyTorch build and installation..."
if ! python3 setup.py install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

echo "Building wheel file..."
python setup.py bdist_wheel --dist-dir="$CURRENT_DIR/"

cd ..

# Basic sanity test (subset)
echo "Running basic sanity test..."
if ! pytest $PACKAGE_NAME/test/test_utils.py; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
