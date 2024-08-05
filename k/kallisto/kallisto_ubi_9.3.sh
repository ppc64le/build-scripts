#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : kallisto
# Version       : v0.51.0
# Source repo   : https://github.com/pachterlab/kallisto
# Tested on     : UBI:9.3
# Language      : C,C++
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

PACKAGE_NAME=kallisto
PACKAGE_VERSION=${1:-v0.51.0}
PACKAGE_URL=https://github.com/pachterlab/kallisto

OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`

yum install -y git make wget gcc-c++ libtool pkg-config cmake zlib zlib-devel libcurl-devel

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

git clone https://github.com/BUStools/bustools.git
cd bustools && mkdir build && cd build && cmake .. && make && make install && cd ../..
cp /usr/local/bin/bustools /usr/bin/bustools

git clone https://github.com/pmelsted/bifrost
cd bifrost && mkdir build && cd build && cmake .. -DCOMPILATION_ARCH=OFF && make && make install && cd ../..

cd ext/htslib && autoheader && autoconf && cd ../..
mkdir build
cd build
cmake .. -DCOMPILATION_ARCH=OFF

if ! make  ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

if ! make install ; then
      echo "------------------$PACKAGE_NAME::Build_and_Install_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Install_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Install_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Install_Success"
      exit 0
fi

