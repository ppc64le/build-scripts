#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#
# Package	: librdkafka
# Version	: v2.5.3
# Source repo	: https://github.com/confluentinc/librdkafka
# Tested on	: UBI 9.3
# Language      : C
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e 
SCRIPT_PACKAGE_VERSION=v2.5.3
PACKAGE_NAME=librdkafka
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/confluentinc/librdkafka
BUILD_HOME=$(pwd)

# Install required dependencies
yum update -y
yum install -y gcc gcc-c++ make git openssl-devel lz4-devel zlib-devel cyrus-sasl-devel libzstd-devel libtool libcurl-devel python3.11.ppc64le python3.11-pip diffutils

#Clone the repository 	
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./configure --install-deps ; then
    echo "------------------$PACKAGE_NAME: configuration fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Configuration_Fails"
    exit 1
fi

if ! make install; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make -C tests run_local_quick; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi