#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : rethinkdb
# Version       : v2.4.4
# Source repo   : https://github.com/rethinkdb/rethinkdb.git
# Tested on     : UBI:9.3
# Language      : C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-v2.4.4}
PACKAGE_URL=https://github.com/rethinkdb/rethinkdb.git
PACKAGE_NAME=rethinkdb

echo "Installing dependencies..."
yum install -y patch bzip2 git make gcc-c++ openssl-devel tar libcurl-devel wget m4 ncurses-devel libicu-devel python3 python3-devel 
yum install -y https://dl.fedoraproject.org/pub/epel/9/Everything/ppc64le/Packages/e/epel-release-9-7.el9.noarch.rpm

echo "Installing protobuf..."
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.19.4/protobuf-cpp-3.19.4.tar.gz
tar -xzf protobuf-cpp-3.19.4.tar.gz --no-same-owner
cd protobuf-3.19.4
./configure --prefix=/usr/local
echo "Starting make..."
make 
echo "Starting make install..."
make install
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
protoc --version

echo "Installing node..."
export NODE_VERSION=${NODE_VERSION:-16}
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

ln -s /usr/bin/python3 /usr/bin/python

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
./configure --allow-fetch 

echo "Installing..."
if ! make && make install ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

echo "Testing..."
if ! make unit; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
