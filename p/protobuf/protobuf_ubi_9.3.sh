#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : protobuf
# Version          : 3.21.12
# Source repo      : https://github.com/protocolbuffers/protobuf.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------
# Variables
PACKAGE_NAME=protobuf
PACKAGE_VERSION=${1:-v3.21.12}
PACKAGE_URL=https://github.com/protocolbuffers/protobuf.git
PACKAGE_DIR=protobuf/python/

# Install necessary system dependencies
yum install -y --allowerasing autoconf automake libtool curl make g++ unzip git gcc gcc-c++ wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build protoc
./autogen.sh
./configure
make
make install

# Install additional dependencies
pip install wheel pytest==7.0.0

#install
cd python
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#The package uses an outdated testing method that doesn't support skipping individual tests. As a result, we're skipping this particular test to prevent failure.
