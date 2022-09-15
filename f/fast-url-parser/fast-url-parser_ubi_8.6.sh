#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: fast-url-parser
# Version	: 1.1.3
# Source repo	: https://github.com/apache/fast-url-parser
# Tested on	: UBI 8.6
# Language      : JavaScript
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


# Install fast-url-parser
npm install $PACKAGE_NAME@$PACKAGE_VERSION


# run tests
git clone $PACKAGE_URL
cd urlparser
git checkout $PACKAGE_VERSION
npm install && npm audit fix && npm audit fix --force;
# fix warning
sed -i 's/{/{ "-W014": true,/' .jshintrc
npm test