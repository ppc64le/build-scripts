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
python${PYTHON_VERSION} -m pip install --upgrade setuptools

# Set environment variable for OpenSSL
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true

# Build the grpcio package
if ! python${PYTHON_VERSION} setup.py bdist_wheel; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi

python${PYTHON_VERSION} -m pip install dist/grpcio-1.64.0-cp39-cp39-linux_ppc64le.whl
if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Build_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Build_Success"
else
     echo "------------------$PACKAGE_NAME::Build_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Build_Fail"
     exit 1
fi

# Test the package
cd ..
python${PYTHON_VERSION} -m pip show grpcio
python${PYTHON_VERSION} -c "import grpc; print(grpc.__file__)"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi
