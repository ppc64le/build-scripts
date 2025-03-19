# ----------------------------------------------------------------------------
# Package  : xerces-c
# Version  : 3.2.5
# Source repo  : https://github.com/apache/xerces-c
# Tested on  : ubi_9.3
# Script License  : Apache License, Version 2 or later
# Maintainer  : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
yum update -y
yum install  git gcc-c++ gcc glibc-devel libtool* autoconf automake make valgrind-devel -y

SCRIPT_PACKAGE_VERSION=v3.2.5
PACKAGE_NAME=xerces-c
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/apache/xerces-c.git

# Clone and build source.
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#configure and build
export XERCESCROOT=`pwd`
./reconf
./configure
make
make install

#run the test suite
make check
