#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: fast-url-parser
# Version	: 1.1.3
# Source repo	: https://github.com/apache/fast-url-parser
# Tested on	: UBI 8.6
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=fast-url-parser
PACKAGE_VERSION=${1:-v1.1.3}
PACKAGE_URL=https://github.com/petkaantonov/urlparser.git
CURDIR="$(pwd)"
dnf install -y wget git yum-utils nodejs nodejs-devel nodejs-packaging npm 

# Install and run tests
git clone $PACKAGE_URL
cd urlparser
git checkout $PACKAGE_VERSION
if ! npm install && npm audit fix && npm audit fix --force; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

# fix warning
sed -i 's/{/{ "-W014": true,/' .jshintrc

if ! npm test; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi