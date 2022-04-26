#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package: jquery-labelauty
# Version: v1.1.4
# Source repo: https://github.com/fntneves/jquery-labelauty 
# Tested on: RHEL v8.5
# Language: PHP
# Travis-Check: True
# Script License: Apache License, Version 2 or later
# Maintainer: Prashant Khoje <prashant.khoje@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex
PACKAGE_NAME=jquery-labelauty
PACKAGE_VERSION=${1:-v1.1.4}
PACKAGE_URL="https://github.com/fntneves/jquery-labelauty"

dnf install -y npm
cd $HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
npm build
npm install
echo "Tests aren't available."

