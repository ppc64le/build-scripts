#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : uue
# Version       : master(e2c4f45e0886ba022a1ef2e1545ada74e1143218)
# Source        : https://github.com/Mithgol/node-uue.git
# Tested on     : RHEL 7.6
# Node Version  : v12.16.1
# Maintainer    : Amol Patil <amol.patil2@ibm.com>
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

PACKAGE_VERSION=e2c4f45e0886ba022a1ef2e1545ada74e1143218

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

git clone https://github.com/Mithgol/node-uue.git && cd node-uue
git checkout $PACKAGE_VERSION


npm install
npm install jshint
npm install -g mocha
npm test

