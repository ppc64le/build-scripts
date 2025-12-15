#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : grpcio
# Version       : v1.64.0
# Source repo   : https://github.com/grpc/grpc.git (# For grpcio - https://github.com.mcas.ms/grpc/grpc/tree/master/src/python/grpcio)
# Tested on     : UBI 8.10
# Language      : C++, Python, C, Starlark, Shell, Ruby
# Ci-Check  : False
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

# Install dependencies
yum install -y python311 python3.11-devel python3.11-pip openssl openssl-devel git gcc gcc-c++ cmake 

# Clone the grpc package.
PACKAGE_NAME=grpc
PACKAGE_VERSION=${1:-v1.64.0}
PACKAGE_URL=https://github.com/grpc/grpc.git

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Setup virtual environment for python
python3.11 -m venv grpcio-env
source grpcio-env/bin/activate
python3 -m pip install pytest hypothesis build

# Install the requirements
python3 -m pip install -r requirements.txt

# Build the package and create whl file
GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 python3 -m build --wheel

# Install wheel
python3 -m pip install dist/grpcio-1.64.0-cp311-cp311-linux_ppc64le.whl
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
python3 -m pip show grpcio
python3 -c "import grpc; print(grpc.__version__)"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     
     # Deactivate python environment (grpcio-env)
      deactivate

     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi

