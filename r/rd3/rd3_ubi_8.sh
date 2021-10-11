# -----------------------------------------------------------------------------
#
# Package       : rd3
# Version       : master
# Source repo   : https://github.com/yang-wei/rd3
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

PACKAGE_NAME=rd3
PACKAGE_URL=https://github.com/yang-wei/rd3

NODE_VERSION=v10.9.0

yum -y update
yum -y install git wget gcc-c++ make python2 bzip2 fontconfig-devel curl

wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s /phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/phantomjs-2.1.1-linux-ppc64/bin/phantomjs

#gulp error with node 12, hence using node 10
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
npm install
npm audit fix
npm audit fix --force
npm i react-dom@^15.4.2
npm i react@^15.7.0
npm run test

