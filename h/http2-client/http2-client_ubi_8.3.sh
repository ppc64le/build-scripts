# ----------------------------------------------------------------------------
#
# Package       : http2-client
# Version       : 1.3.3
# Source repo   : https://github.com/hisco/http2-client
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

PACKAGE_NAME=http2-client
PACKAGE_VERSION=${1:-v1.3.3}              
PACKAGE_URL=https://github.com/hisco/http2-client

# install dependencies
yum update -y 
yum install git wget -y

# install nodejs
dnf module enable nodejs:12 -y
dnf install nodejs -y

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# to install 
npm install yarn -g
yarn --ignore-engines
yarn install

# to execute tests
yarn test