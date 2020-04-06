#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package	: jsdom
# Version	: 9.11.0
# Source repo	: https://github.com/jsdom/jsdom.git 
# Tested on	: RHEL 7.6
# Script License: 
# Maintainer	: Sarvesh Tamba <sarvesh.tamba@ibm.com>
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
npm install yarn -g

# Clone and build npm package from source.
git clone https://github.com/jsdom/jsdom.git
cd jsdom/
git checkout 9.11.0
 
npm config set unsafe-perm true
yarn
# Currently ignoring the test case execution due to issues in yarn test
# Reference:- https://github.com/jsdom/jsdom/issues/2887
#yarn test
npm config set unsafe-perm false