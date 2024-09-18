#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : cyrus-sasl
# Version       : cyrus-sasl-2.1.28
# Source repo   : https://github.com/cyrusimap/cyrus-sasl
# Tested on     : UBI: 9.3
# Language      : C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=cyrus-sasl
PACKAGE_VERSION=${1:-cyrus-sasl-2.1.28}
PACKAGE_URL=https://github.com/cyrusimap/cyrus-sasl

yum install -y gcc gcc-c++ make wget git cmake 
yum install -y autoconf automake openssl openssl-devel openssl-libs libtool

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

./autogen.sh
./configure --build ppc64le

if ! make ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make check ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
