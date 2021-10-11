#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : engine.io-parser
# Version       : v2.1.3
# Source        : https://github.com/socketio/engine.io-parser.git
# Tested on     : RHEL 7.6
# Node Version  : v12.19.1
# Maintainer    : Sudeep Raj <sudeep.raj2@ibm.com>
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

PACKAGE_VERSION=2.1.3

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y openssl-devel.ppc64le curl git
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v12.19.1
if [ `nvm list | grep -c "v12.19.1"` -eq 0 ]
then
        nvm install v12.19.1
fi

nvm alias default v12.19.1

#Updating package installer and prerquisites
sudo yum -y install vim git curl wget make

#Installing nodejs v12.19.1 by using nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 12.19.1 && node -v

#1. Building ngrok version 3.4.0 from github
git clone https://github.com/bubenshchykov/ngrok.git && cd ngrok
git checkout v3.4.0
sed -i -e "47 a linuxppc64: cdn + cdnPath + 'linux-ppc64le.zip' ," download.js
npm install

#2. Building zulngrok version 4.1.0
cd ..
git clone https://github.com/rase-/zuul-ngrok.git && cd zuul-ngrok
npm install --save file:../ngrok

#3. Building engine.io-parser
cd ..
git clone https://github.com/socketio/engine.io-parser.git && cd engine.io-parser/
git checkout $PACKAGE_VERSION
npm install --save file:../zuul-ngrok

npm -y install --save-dev mocha
npm install

npm test




