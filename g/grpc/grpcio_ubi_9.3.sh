#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : grpcios
# Version       : v1.64.0
# Source repo   : https://github.com/grpc/grpc.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=grpc
PACKAGE_VERSION=${1:-v1.64.0}
PYTHON_VERSION=${2:-3.9}
PACKAGE_URL=https://github.com/grpc/grpc.git

# Update the package manager
yum update -y

# Install necessary development tools and libraries
yum install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-setuptools git cmake autoconf libtool gcc gcc-c++ make openssl-devel zlib-devel libuuid-devel gcc-gfortran

# Clone the gRPC repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME

# Initialize submodules
git submodule update --init

# Checkout the specified version
git checkout $PACKAGE_VERSION

# Install required Python dependencies
python${PYTHON_VERSION} -m pip install -r requirements.txt
# Upgrade setuptools
python${PYTHON_VERSION} -m pip install --upgrade setuptools absl-py

# Set environment variable for OpenSSL
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true

# Build the grpcio package
if ! python${PYTHON_VERSION} setup.py bdist_wheel; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi

# Install the created wheel
if ! python${PYTHON_VERSION} -m pip install dist/*.whl; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run specific tests
cd src/python/grpcio_tests
export PYTHONPATH=$(pwd)
if ! python${PYTHON_VERSION} -m unittest tests.unit._invalid_metadata_test tests.unit._compression_test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Success_But_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
