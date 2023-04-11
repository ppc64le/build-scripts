#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : node-jwks-rsa
# Version       : v3.0.1
# Source repo   : https://github.com/auth0/node-jwks-rsa.git
# Tested on     : UBI: 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=node-jwks-rsa
PACKAGE_VERSION=${1:-v3.0.1}
PACKAGE_URL=https://github.com/auth0/node-jwks-rsa.git
HOME_DIR=${PWD}

yum update -y
yum install -y yum-utils git wget tar gzip 

#Installing Nodejs v14.21.2
cd $HOME_DIR
wget https://nodejs.org/dist/v14.21.2/node-v14.21.2-linux-ppc64le.tar.gz
tar -xzf node-v14.21.2-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v14.21.2-linux-ppc64le/bin:$PATH
node -v
npm -v

# Clone node-jwks-rsa repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Install required dependencies for node-jwks-rsa
if ! npm install; then
        echo "Install Fails"
		exit 1
fi 

#Run tests
npm run lint

if ! npm test; then
        echo "Test Fails"
        exit 2
else
        echo "Install and Test Success"
        exit 0
fi