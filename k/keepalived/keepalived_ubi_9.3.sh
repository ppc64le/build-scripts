#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : keepalived
# Version       : v2.2.8
# Source repo   : https://github.com/acassen/keepalived
# Tested on     : UBI 9.3
# Language      : C
# Travis-Check  : True
# Script License: GNU GENERAL PUBLIC LICENSE
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=keepalived
PACKAGE_VERSION=${1:-v2.2.8}
PACKAGE_URL=https://github.com/acassen/keepalived

yum install -y yum-utils git gcc-c++ gcc diffutils patch libtool automake autoconf make cmake  openssl-devel openssl

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
./autogen.sh

if ! ./configure ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_Build_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_Build_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Build_Success"
    exit 0
fi
