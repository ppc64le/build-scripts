#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : call-bind
# Version       : v1.0.2
# Source repo   : https://github.com/ljharb/call-bind.git
# Tested on     : UBI 8.4
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {Sapana.Khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#Variables
PACKAGE_URL=https://github.com/ljharb/call-bind.git
PACKAGE_NAME=call-bind
#Test fails for required version and latest stable version
PACKAGE_VERSION=${1:-v1.0.2}

NODE_VERSION=v12.22.9

#Install dev dependencies 
yum install -y git wget

#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc

#install node
nvm install $NODE_VERSION

#Cloning Repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#rm -f package-lock.json
#Build package
npm install
#npm i --package-lock-only
#npm audit fix --force

#Test pacakge
npm run tests-only
