#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : socket.io-parser
# Version       : 3.3.0
# Source        : https://github.com/socketio/socket.io-parser.git
# Tested on     : RHEL 7.6
# Node Version  : v12.19.1
# Maintainer    : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

set -e

# Install all dependencies.
sudo yum clean all
sudo yum -y update

PACKAGE_VERSION=3.3.0

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y curl git make
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v12.19.1
if [ `nvm list | grep -c "v12.19.1"` -eq 0 ]
then
        nvm install v12.19.1
fi

nvm alias default v12.19.1

# Build ngrok version 3.4.0 which is a build dependency
git clone https://github.com/bubenshchykov/ngrok.git && cd ngrok
git checkout v3.4.0
sed -i -e "47 a linuxppc64: cdn + cdnPath + 'linux-ppc64le.zip' ," download.js
npm install

# Build zuul-ngrok version 4.1.0 which is a build dependency
cd ..
git clone https://github.com/rase-/zuul-ngrok.git && cd zuul-ngrok
git checkout v4.1.0
npm install --save file:../ngrok

# Build socket.io-parser
cd ..
git clone https://github.com/socketio/socket.io-parser.git && cd socket.io-parser
git checkout $PACKAGE_VERSION
npm install --save file:../zuul-ngrok
npm install
npm test

