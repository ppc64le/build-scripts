# ----------------------------------------------------------------------------
#
# Package         : fbjs
# Version         : v0.6.1
# Source repo     : https://github.com/facebook/fbjs.git
# Tested on       : UBI 8.0
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
# ----------------------------------------------------------------------------

# variables
PKG_NAME="fbjs"
PKG_VERSION="v0.6.1"

echo "Usage: $0 [v<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v0.6.1"

PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
yum -y update
yum install -y git wget.ppc64le openssl-devel.ppc64le 
yum module list nodejs
yum module install -y nodejs:12
npm install yarn --global

# create folder for saving logs
mkdir -p /logs
LOGS_DIRECTORY=/logs

LOCAL_DIRECTORY=/root

#clone and build 
cd $LOCAL_DIRECTORY
git clone https://github.com/facebook/fbjs.git $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/

git checkout $PKG_VERSION

yarn install --frozen-lockfile

yarn run fbjs:build | tee $LOGS_DIRECTORY/$PKG_NAME-log.txt

yarn run fbjs:test | tee $LOGS_DIRECTORY/$PKG_NAME_Test-log.txt
