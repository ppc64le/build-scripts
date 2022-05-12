#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: brotli
# Version	: v1.0.9
# Source repo	: https://github.com/google/brotli
# Tested on	: UBI: 8.5
# Language      : C
# Travis-Check  : True
# Script License: MIT License
# Maintainer	: Vishaka Desai <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=brotli
PACKAGE_VERSION=${1:-v1.0.9}
PACKAGE_URL=https://github.com/google/brotli

yum -y update --nobest && yum install -y cmake make git gcc-c++

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mkdir out && cd out
../configure-cmake
make

if ! make install; then
	echo "------------------Build_fails---------------------"
	exit 1
else
	echo "------------------Build_success-------------------------"
	# exit 0
fi


if ! make test; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	# exit 0
fi