# -----------------------------------------------------------------------------
#
# Package       : asynckit
# Version       : v0.4.0
# Source repo   : https://github.com/alexindigo/asynckit
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
PACKAGE_VERSION=v0.4.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is v0.4.0"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

PACKAGE_NAME=asynckit
PACKAGE_URL=https://github.com/alexindigo/asynckit

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

yum -y update
yum -y install git wget fontconfig-devel bzip2

#install phantomjs
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s /phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/phantomjs-2.1.1-linux-ppc64/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install
npm test
