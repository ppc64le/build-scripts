
# ----------------------------------------------------------------------------
#
# Package         : Highlight.js
# Version         : 9.15.10
# Source repo     : https://github.com/highlightjs/highlight.js.git
# Tested on       : UBI 8.0
# Script License  : BSD-3-Clause License
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
# Node.js 
#
# ----------------------------------------------------------------------------

# variables
PKG_NAME="highlight.js"
PKG_VERSION="9.15.10"
REPOSITORY="https://github.com/highlightjs/highlight.js.git"

echo "Usage: $0 [v<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is 9.15.10"

PKG_VERSION="${1:-$PKG_VERSION}"

yum -y update
yum install -y git wget.ppc64le openssl-devel.ppc64le
yum module list nodejs
yum module install -y nodejs:12
npm install yarn --global

# create folder for saving logs
mkdir -p /logs

# variables
LOGS_DIRECTORY=/logs


git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout $PKG_VERSION
git branch
   
npm install

npm run build
npm run test
   
npm run build-browser
npm run test-browser
