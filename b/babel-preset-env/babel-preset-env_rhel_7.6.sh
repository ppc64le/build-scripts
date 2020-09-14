#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package	: babel-preset-env 
# Version	: 1.2.1
# Source repo	: https://github.com/babel/babel-preset-env.git 
# Tested on	: RHEL 7.6
# Script License: MIT License
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

# Clone and build npm package from source.
git clone https://github.com/babel/babel-preset-env.git
cd babel-preset-env
git checkout v1.2.1 
 
npm config set unsafe-perm true
npm install
npm test
npm config set unsafe-perm false
