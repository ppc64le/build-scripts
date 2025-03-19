#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package  : xerces-c
# Version  : v3.2.5
# Source repo  : https://github.com/apache/xerces-c
# Tested on  : UBI 9.3
# Language      : C++
# Travis-Check  : true
# Script License  : Apache License, Version 2 or later
# Maintainer  : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

SCRIPT_PACKAGE_VERSION=v3.2.5
PACKAGE_NAME=xerces-c
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/apache/xerces-c.git

#Install dependencies.
yum update -y
yum install  git gcc-c++ gcc glibc-devel libtool* autoconf automake make valgrind-devel -y

#Clone and build source.
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Configure and build
export XERCESCROOT=`pwd`
./reconf
./configure
make
make install

#run the test suite
make check
echo "SUCCESS: Build and test success!"
