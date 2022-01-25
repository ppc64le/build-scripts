# ----------------------------------------------------------------------------
#
# Package       : istanbul-lib-instrument
# Version       : 5.1.0
# Source repo   : https://github.com/istanbuljs/istanbuljs
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -e

WORK_DIR=`pwd`

PACKAGE_NAME=istanbul-lib-instrument
PACKAGE_VERSION=${1:-istanbul-lib-instrument-v5.1.0}               
PACKAGE_URL=https://github.com/istanbuljs/istanbuljs

# install dependencies
yum update -y 
yum install git wget -y

# install nodejs
dnf module enable nodejs:12 -y
dnf install nodejs -y

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL
cd istanbuljs
git checkout $PACKAGE_VERSION
cd /istanbuljs/packages/istanbul-lib-instrument

# to install 
npm install yarn -g
yarn install

# to execute tests
yarn test