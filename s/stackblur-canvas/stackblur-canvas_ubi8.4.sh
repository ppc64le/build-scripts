# -----------------------------------------------------------------------------
#
# Package	: stackblur-canvas
# Version	: 2.5.0
# Source repo	: https://github.com/flozz/StackBlur
# Tested on	: UBI 8.4
# Language      : Node
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {Sapana.Khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=stackblur-canvas
PACKAGE_VERSION=v2.5.0
PACKAGE_URL=https://github.com/flozz/StackBlur

set -e

yum install -y git npm nodejs

git clone $PACKAGE_URL
cd StackBlur
git checkout $PACKAGE_VERSION

# install dependencies
npm install 

# build code
npm run rollup

# test fails with error "no tests available"
npm test

exit

