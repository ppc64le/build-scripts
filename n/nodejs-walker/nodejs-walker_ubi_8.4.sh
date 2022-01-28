# -----------------------------------------------------------------------------
#
# Package       : nodejs-walker
# Version       : master
# Source repo   : https://github.com/daaku/nodejs-walker
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : sethp@us.ibm.com
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#The tags are too old and have failures on both Power and Intel
PACKAGE_VERSION=master

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is master"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

PACKAGE_NAME=nodejs-walker
PACKAGE_URL=https://github.com/daaku/nodejs-walker


sudo dnf -y update
sudo dnf -y module enable nodejs:12
sudo dnf -y install git nodejs

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install
npm test
