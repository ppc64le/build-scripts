# ----------------------------------------------------------------------------
#
# Package       : shared-cursor
# Version       : v1.0.2
# Source repo   : https://github.com/rtc-io/rtc-sharedcursor
# Tested on     : ubi: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Hari Pithani <Hari.Pithani@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

PACKAGE_VERSION=v1.0.2

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is v1.0.2"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

PACKAGE_NAME=rtc-sharedcursor
PACKAGE_URL=https://github.com/rtc-io/rtc-sharedcursor.git

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
npm test