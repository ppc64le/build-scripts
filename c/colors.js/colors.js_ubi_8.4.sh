#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : colors.js
# Version       : v1.0.3, v1.1.2, v1.4.0, v1.3.3
# Source repo   : https://github.com/Marak/colors.js
# Tested on     : UBI 8.4
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : sethp@us.ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_VERSION=v1.0.3

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is v1.0.3"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

PACKAGE_NAME=colors.js
PACKAGE_URL=https://github.com/Marak/colors.js

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

yum -y update
yum -y install git

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install
npm test
