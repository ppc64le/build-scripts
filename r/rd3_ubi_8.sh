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

yum -y update
yum -y install git wget gcc-c++ make python2 bzip2 fontconfig-devel

tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s /phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/phantomjs-2.1.1-linux-ppc64/bin/phantomjs

#gulp error with node 12, hence using node 10
wget https://nodejs.org/dist/v10.9.0/node-v10.9.0-linux-ppc64le.tar.gz
tar -xzf node-v10.9.0-linux-ppc64le.tar.gz
ln -s /node-v10.9.0-linux-ppc64le/bin/npm /usr/local/bin/npm
ln -s /node-v10.9.0-linux-ppc64le/bin/node /usr/local/bin/node
export PATH=$PATH:/node-v10.9.0-linux-ppc64le/bin/npm:/node-v10.9.0-linux-ppc64le/bin/node

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
npm install

npm run test

