#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : istanbul-reports
# Version       : istanbul-reports-v3.0.5
# Source repo   : https://github.com/istanbuljs/istanbuljs.git
# Tested on     : UBI: 8.3
# Language      : NPM
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Raju Sah <Raju.Sah@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_URL=https://github.com/istanbuljs/istanbuljs.git
PACKAGE_NAME=istanbuljs
PACKAGE_VERSION=${1:-istanbul-reports-v3.0.5}

# install tools and dependent packages
yum install -y git npm 
npm i chai clone

#Cloning Repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install 
npm test
