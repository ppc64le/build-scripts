# ----------------------------------------------------------------------------
#
# Package         : node-sass
# Version         : v4.14.1
# Source repo     : https://github.com/sass/node-sass.git
# Tested on       : rhel 8.4
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
#nodejs
# 
#python2 
# ----------------------------------------------------------------------------

# variables
PKG_NAME="node-sass"
PKG_VERSION="v4.14.1"
REPOSITORY="https://github.com/sass/node-sass.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v4.14.1"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update && yum install -y yum-utils git wget openssl-devel python2 nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses gcc gcc-c++ libffi libffi-devel jq make cmake

yum module list nodejs
yum module install -y nodejs:14
npm install yarn --global

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

LOCAL_DIRECTORY=/root

#clone and build 
cd $LOCAL_DIRECTORY	
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout $PKG_VERSION
git branch

npm install --unsafe-perm | tee $LOGS_DIRECTORY/$PKG_NAME.txt
node scripts/build -f

npm test | tee $LOGS_DIRECTORY/$PKG_NAME_Test.txt
