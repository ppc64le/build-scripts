#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: cli-table3
# Version	: v0.5.1
# Source repo	: https://github.com/cli-table/cli-table3
# Tested on	: UBI 8.4
# Language      : Node
# Travis-Check  : True
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

PACKAGE_NAME=cli-table3
PACKAGE_VERSION=${1:-v0.5.1}
PACKAGE_URL=https://github.com/cli-table/cli-table3

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is v0.5.1"

# install tools and dependent packages
yum -y update
yum -y install git wget gcc-c++ make python2 curl

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

# clone, build and test specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install

npm test

exit 0

