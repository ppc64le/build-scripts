# -----------------------------------------------------------------------------
#
# Package       : caniuse-lite
# Version       : v1.0.30001173 , v1.0.30001185, v1.0.30001148, v1.0.30001151, v1.0.30001097 & v1.0.30001205
# Source repo   : https://github.com/browserslist/caniuse-lite
# Tested on     : UBI 8
# Language      : Java Script
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Hari Pithani <Hari.Pithani@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_VERSION=v1.0.30001173

echo "Usage: $0 [ <PACKAGE_VERSION> ]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is v1.0.30001173"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

set -e

PACKAGE_NAME=caniuse-lite
PACKAGE_URL=https://github.com/browserslist/caniuse-lite.git

NODE_VERSION=v12.22.4

yum -y update
yum -y install git wget gcc-c++ make python2 curl

#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

#For rerunning build
if [ -d "caniuse-lite" ] ; then
  rm -rf caniuse-lite
fi

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install
npm audit fix
npm test
