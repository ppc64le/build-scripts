#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : grpcio
# Version       : v1.68.0
# Source repo   : https://github.com/grpc/grpc.git (# For grpcio - https://github.com.mcas.ms/grpc/grpc/tree/master/src/python/grpcio)
# Tested on     : UBI 9.3
# Language      : C++, Python, C, Starlark, Shell, Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandan.Abhyankar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=grpc
PACKAGE_VERSION=${1:-v1.68.0}
PACKAGE_URL=https://github.com/grpc/grpc.git
PYTHON_VERSION=${PYTHON_VERSION:-3.11}
# Install dependencies
yum install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip openssl openssl-devel git gcc-toolset-13 cmake zlib-devel libuuid-devel
source /opt/rh/gcc-toolset-13/enable

if [ -z $PACKAGE_SOURCE_DIR ]; then
    git clone $PACKAGE_URL -b $PACKAGE_VERSION
    cd $PACKAGE_NAME
else
    cd $PACKAGE_SOURCE_DIR
fi

git checkout $PACKAGE_VERSION

git submodule update --init --recursive

python${PYTHON_VERSION}  -m pip install pytest hypothesis build six

# Install requirements
python${PYTHON_VERSION}  -m pip install -r requirements.txt

python${PYTHON_VERSION} -m pip install --upgrade setuptools

# Install the package
GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 python${PYTHON_VERSION}  -m pip install -e .

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
fi
