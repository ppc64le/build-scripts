# -----------------------------------------------------------------------------
#
# Package       : node-stack-trace
# Version       : v0.0.10
# Source repo   : https://github.com/felixge/node-stack-trace
# Tested on     : UBI 8.4
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
PACKAGE_VERSION=v0.0.10

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is v0.0.10"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

PACKAGE_NAME=node-stack-trace
PACKAGE_URL=https://github.com/felixge/node-stack-trace

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

#There are no tests for verified version, uncomment this for future versions, if needed
#npm test
