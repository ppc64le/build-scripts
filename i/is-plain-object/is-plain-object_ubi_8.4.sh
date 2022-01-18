# -----------------------------------------------------------------------------
#
# Package       : is-plain-object
# Version       : 2.0.4
# Source repo   : https://github.com/jonschlinkert/is-plain-object.git
# Tested on     : UBI 8
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
PACKAGE_VERSION=2.0.4

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is v2.0.4"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

PACKAGE_NAME=is-plain-object
PACKAGE_URL=https://github.com/jonschlinkert/is-plain-object.git

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
yes | cp /usr/local/bin/phantomjs /$PACKAGE_NAME/node_modules/mocha-phantomjs/node_modules/phantomjs/lib/phantom/bin/
npm test
