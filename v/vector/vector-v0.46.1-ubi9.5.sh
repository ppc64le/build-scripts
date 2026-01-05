#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : vector
# Version       : v0.46.1
# Source repo   : https://github.com/vectordotdev/vector
# Tested on     : UBI 9.5 (docker)
# Language      : Rust
# Ci-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=vector
PACKAGE_VERSION=${1:-v0.46.1}
PACKAGE_URL=https://github.com/vectordotdev/${PACKAGE_NAME}.git
PROTOBUF_VERSION=3.15.0
WDIR=$(pwd)
PATH=$HOME/.cargo/bin:$PATH

#Install ubi deps
yum install -y gcc gcc-c++ make cmake wget unzip git python-devel openssl-devel golang cyrus-sasl-devel perl-IPC-Cmd perl-FindBin perl-File-Compare perl-File-Copy findutils

#Install protobuf
cd /tmp
wget https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOBUF_VERSION/protoc-$PROTOBUF_VERSION-linux-ppcle_64.zip
unzip protoc-$PROTOBUF_VERSION-linux-ppcle_64.zip
cp -r include/* /usr/local/include
cp bin/protoc /usr/local/bin
rm -rf bin include readme.txt protoc-$PROTOBUF_VERSION-linux-ppcle_64.zip

#Install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

#Clone repo
cd $WDIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
ret=0
make build || ret=$?
if [ "$ret" -ne 0 ]
then
        echo "FAIL: Build failed."
	exit 1
fi
export VECTOR_BIN=$WDIR/$PACKAGE_NAME/target/release/vector

#Smoke test
$VECTOR_BIN --version || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Smoke test failed."
	exit 2
fi

#Unit test
cargo install cargo-nextest
make test || ret=$?
if [ "$ret" -ne 0 ]
then
        echo "FAIL: Unit test failed."
        exit 2
fi

set +ex
echo "Build and test successful!"
echo "vector binary available at [$VECTOR_BIN]"

