#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: xerces-c
# Version	: v3.2.5
# Source repo	: https://github.com/apache/xerces-c
# Tested on	: UBI 9.3
# Language      : C++
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xerces-c
PACKAGE_VERSION=${1:-v3.2.5}
PACKAGE_URL=https://github.com/apache/$PACKAGE_NAME.git  

#Install libs
yum install  git gcc-c++ gcc glibc-devel libtool* autoconf automake make -y

#Get repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Configure and Build
export XERCESCROOT=`pwd`
./reconf
./configure

ret=0
make -j $(nproc) || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi

make install -j $(nproc) || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi

#Test
make check || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Tests failed."
	exit 2
fi

echo "SUCCESS: Build and test success!"
