#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: protobuf-c
# Version	: v1.3.0
# Source repo	: https://github.com/protobuf-c/protobuf-c
# Tested on	: UBI: 8.5
# Language      : c,c++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=protobuf-c
PACKAGE_VERSION=${1:-v1.3.0}
PACKAGE_URL=https://github.com/protobuf-c/protobuf-c

yum install -y git make gcc-c++ make cmake wget autoconf automake libtool bzip2 unzip libffi-devel clang clang-devel llvm-devel llvm-static clang-libs 

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export PROTOBUF_VERSION=v3.0.2
export PKG_CONFIG_PATH=$HOME/protobuf-$PROTOBUF_VERSION-bin/lib/pkgconfig


git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout $PROTOBUF_VERSION
./autogen.sh && ./configure --prefix=$HOME/protobuf-$PROTOBUF_VERSION-bin && make -j2 && make install 
cd ..

chmod u+x ./autogen.sh
./autogen.sh
./configure
make

if ! make install; then
	echo "------------------Build_fails---------------------"
	exit 1
else
	echo "------------------Build_success-------------------------"
	
fi


if ! make check; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	
fi