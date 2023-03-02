#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: rocksdb
# Version	: v7.9.2
# Source repo	: https://github.com/facebook/rocksdb
# Tested on	: UBI: 8.5
# Language      : C++ 
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=rocksdb
PACKAGE_VERSION=${1:-v7.9.2}
PACKAGE_URL=https://github.com/facebook/rocksdb

yum -y update && yum install -y python38 python38-devel python39 python39-devel python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake wget

yum install -y zlib zlib-devel
yum install -y bzip2 bzip2-devel
yum install -y lz4-devel
yum install -y libasan

cd $HOME
wget https://github.com/facebook/zstd/archive/v1.1.3.tar.gz
mv v1.1.3.tar.gz zstd-1.1.3.tar.gz
tar zxvf zstd-1.1.3.tar.gz
cd zstd-1.1.3
make && sudo make install

cd ..
git clone https://github.com/gflags/gflags
cd gflags/
mkdir build && cd build
ccmake ..
make
make install

cd ..
git clone  $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! sudo make static_lib; then
	echo "Build fails"
	exit 1
else
	echo "Build successful"
	exit 0
fi


# The "make check" command requires high end VM.
# If users have a high end vm and want to run tests, they can uncomment "make check" and run tests.
# "make check" will compile and run all the unit tests. It will compile RocksDB in debug mode.
# It also requires a change using sed to test in UBI container

#cd util
#sed -i '101d' hash.cc
#cd ..
#if ! make check; then
#	echo "Test fails"
#	exit 2
#else
#	echo "Build and test success"
#	exit 0
#fi
