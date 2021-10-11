# -----------------------------------------------------------------------------
#
# Package       : jsbn
# Version       : master
# Source repo   : https://github.com/andyperlitch/jsbn
# Tested on     : UBI 8
# Script License: Apache License, Version 2 or later
# Maintainer    : swati.singhal@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_VERSION=master

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is master"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

PACKAGE_NAME=jsbn
PACKAGE_URL=https://github.com/andyperlitch/jsbn

NODE_VERSION=v12.22.4

yum -y update
yum -y install git wget gcc-c++ make python2 curl

#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install
npm audit fix

#no tests to run


