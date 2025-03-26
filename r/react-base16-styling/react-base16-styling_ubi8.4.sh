# -----------------------------------------------------------------------------
#
# Package	: react-base16-styling
# Version	: 0.8.1
# Source repo	: https://github.com/reduxjs/redux-devtools
# Tested on	: UBI8.4
# Language      : Node
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {sapana.khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=react-base16-styling
PACKAGE_VERSION=react-base16-styling@0.8.1
PACKAGE_URL=https://github.com/reduxjs/redux-devtools

set -e

yum install -y git npm nodejs

npm install jest 
npm install ts-jest

git clone $PACKAGE_URL
cd redux-devtools
git checkout $PACKAGE_VERSION
cd packages/$PACKAGE_NAME
npm install
npm test

exit 0

