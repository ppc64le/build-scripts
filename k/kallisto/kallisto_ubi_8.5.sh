#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : kallisto
# Version       : v0.48.0
# Source repo   : https://github.com/pachterlab/kallisto
# Tested on     : UBI 8.5
# Language      : C,C++
# Travis-Check  : True
# Script License: BSD-2-Clause license
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=kallisto
PACKAGE_VERSION=${1:-v0.48.0}
PACKAGE_URL=https://github.com/pachterlab/kallisto

OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`

yum update -y
yum install -y git make wget gcc-c++ libtool pkg-config cmake zlib zlib-devel libcurl

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

git clone https://github.com/BUStools/bustools.git
cd bustools && mkdir build && cd build && cmake .. && make && make install && cd ../..

cd ext/htslib && autoheader && autoconf && cd ../..
mkdir build
cd build
cmake .. -DBUILD_FUNCTESTING=ON

if ! make install ; then
      echo "------------------$PACKAGE_NAME::Install_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail | Install_fails"
fi

if ! make ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

if ! make test ; then
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

