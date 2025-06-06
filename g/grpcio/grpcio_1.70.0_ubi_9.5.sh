#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : grpcio
# Version       : v1.70.0
# Source repo   : https://github.com/grpc/grpc.git (# For grpcio - https://github.com.mcas.ms/grpc/grpc/tree/master/src/python/grpcio)
# Tested on     : UBI 9.5
# Language      : C++, Python, C, Starlark, Shell, Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Srighakollapu.Sai.Srivatsa@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install dependencies
yum install -y python3 python3-devel python3-pip openssl openssl-devel git gcc-toolset-13 gcc-toolset-13-gcc-c++

# Clone the grpc package.
PACKAGE_NAME=grpc
PACKAGE_VERSION=${1:-v1.70.0}
PACKAGE_URL=https://github.com/grpc/grpc.git

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

pip3 install setuptools coverage cython protobuf==4.25.3 wheel cmake==3.*

export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true
export GRPC_PYTHON_BUILD_WITH_CYTHON=1
export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:${PATH}"

# Install the package
pip3 install .

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
python3 -c "import grpc; import grpc._cython; import grpc._cython._cygrpc; import grpc.beta; import grpc.framework; import grpc.framework.common; import grpc.framework.foundation; import grpc.framework.interfaces; import grpc.framework.interfaces.base; import grpc.framework.interfaces.face; print('All modules imported successfully')"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"

else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi
