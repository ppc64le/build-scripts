# ----------------------------------------------------------------------------
#
# Package         : date-fns
# Version         : v1.29.0
# Source repo     : https://github.com/date-fns/date-fns.git
# Tested on       : UBI 8
# Script License  : MIT License
# Maintainer      : Manik Fulpagar <Manik.Fulpagar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# ----------------------------------------------------------------------------
# Prerequisites:
#
# Node.js and Yarn.
#
# phantomjs and fontconfig-devel
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="date-fns"
PKG_VERSION="v1.29.0"
PKG_VERSION_LATEST="v2.22.1"

echo "Usage: $0 [v<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v1.29.0"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update
yum install -y git cmake make gcc-c++ autoconf ncurses-devel.ppc64le wget.ppc64le openssl-devel.ppc64le diffutils procps-ng bzip2 python3 fontconfig-devel
yum module list nodejs
yum module install -y nodejs:14
npm install yarn --global

#install phantomjs 
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 
mv phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin
rm -rf phantomjs-2.1.1-linux-ppc64.tar.bz2

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

#clone  and build date-fns
git clone https://github.com/date-fns/date-fns.git $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout -b $PKG_VERSION

yarn install | tee $LOGS_DIRECTORY/$PKG_NAME-log.txt

export CHROME_BIN=chromium-browser

yarn test


