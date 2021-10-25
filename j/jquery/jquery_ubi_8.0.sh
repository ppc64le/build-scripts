# ----------------------------------------------------------------------------
#
# Package         : jquery
# Version         : 3.4.0
# Source repo     : https://github.com/jquery/jquery
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
# node js must be installed.
#
# chrome and firefox must be installed
# ----------------------------------------------------------------------------

#Variables
PKG_NAME="jquery"
PKG_VERSION="3.4.0"
REPOSITORY="https://github.com/jquery/jquery.git"

echo "Usage: $0 [<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is 3.4.0"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update && yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake

yum install -y firefox liberation-fonts xdg-utils && npm install n -g && n latest && npm install -g npm@latest && export PATH="$PATH" && npm install --global yarn grunt-bump xo testem acorn

# install nodejs
# wget https://nodejs.org/dist/v16.4.2/node-v16.4.2-linux-ppc64le.tar.gz
# tar -xzf node-v16.4.2-linux-ppc64le.tar.gz
# export PATH=$CWD/node-v16.4.2-linux-ppc64le/bin:$PATH

#export CHROME_BIN='/root/chromium_84_0_4118_0'
#export CHROME_BIN=chromium-browser

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

LOCAL_DIRECTORY=/root

#clone and build 
cd $LOCAL_DIRECTORY
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git branch
git checkout $PKG_VERSION
git branch

npm run build | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt

npm run test:browserless

