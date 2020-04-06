#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package	: jwt-node 
# Version	: master
# Source repo	: https://github.com/mattrobenolt/jwt-node.git
# Tested on	: RHEL 7.6
# Script License: 
# Maintainer	: Sarvesh Tamba <sarvesh.tamba@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install all dependencies.
sudo yum -y update
sudo yum install -y java-1.8.0-openjdk

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y openssl-devel.ppc64le curl git
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v12.16.1
if [ `nvm list | grep -c "v12.16.1"` -eq 0 ]
then
        nvm install v12.16.1
fi

nvm alias default v12.16.1

# Download source dependencny node-base64.
git clone https://github.com/chentsulin/node-base64.git

# Clone and build npm package from source.
git clone https://github.com/mattrobenolt/jwt-node.git
cd jwt-node/
 
npm config set unsafe-perm true
npm install ../node-base64
npm install
#npm test #no test specified
npm config set unsafe-perm false