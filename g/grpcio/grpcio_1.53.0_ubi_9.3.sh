#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : grpcio
# Version       : v1.53.0
# Source repo   : https://github.com/grpc/grpc.git (# For grpcio - https://github.com.mcas.ms/grpc/grpc/tree/master/src/python/grpcio)
# Tested on     : UBI 9.3
# Language      : C++, Python, C, Starlark, Shell, Ruby
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhijeet.Dandekar1@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install dependencies
yum install -y python3 python3-devel python3-pip openssl openssl-devel git gcc gcc-c++ cmake

# Clone the grpc package.
PACKAGE_NAME=grpc
PACKAGE_VERSION=${1:-v1.53.0}
PACKAGE_URL=https://github.com/grpc/grpc.git

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

python3 -m pip install pytest hypothesis build six

# Install requirements
python3 -m pip install "coverage>=4.0" "cython>=0.29.8,<3.0.0" "protobuf>=4.21.3,<5.0dev" "wheel>=0.29"

# Install the package
if ! (GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 python3 -m pip install -e .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Test the package
cd ..

python3 -m pip show grpcio

if ! (python3 -c "import grpc; print(grpc.__version__)"); then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
