#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : php-ext-brotli
# Version          : 0.13.1
# Source repo      : https://github.com/kjdev/php-ext-brotli.git
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vathsala . <Vaths367@in.ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables

PACKAGE_NAME=php-ext-brotli
PACKAGE_URL=https://github.com/kjdev/php-ext-brotli.git
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:0.13.1}

yum install -y git automake libtool make unzip gcc-c++ autoconf zlib xz m4 gettext help2man wget diffutils php-devel

git clone --recursive --depth=1 $PACKAGE_URL
cd $PACKAGE_NAME

git checkout "$PACKAGE_VERSION"

phpize
./configure
if ! make && make install ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi
if ! make test; then
        echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
        exit 0
fi
