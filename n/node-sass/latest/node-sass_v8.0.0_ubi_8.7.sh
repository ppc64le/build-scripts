#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : node-sass
# Version          : v8.0.0
# Source repo      : https://github.com/sass/node-sass
# Tested on        : UBI 8.7
# Language         : Node
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=node-sass
PACKAGE_VERSION=${1:-v8.0.0}
PACKAGE_URL=https://github.com/sass/node-sass.git

yum -y update && yum install -y yum-utils git wget openssl-devel python2 nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses gcc gcc-c++ libffi libffi-devel jq make cmake

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! npm install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

node scripts/build -f
sed -i "46 s/default: return false;/case 'ppc64':return '64-bit'; \n\t default: return false;/" lib/extensions.js

#Build and test

if ! npm test; then
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

