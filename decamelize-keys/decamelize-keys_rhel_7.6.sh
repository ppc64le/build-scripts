#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : decamelize-keys
# Version       : v1.1.0
# Source        : https://github.com/dsblv/decamelize-keys.git 
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

PACKAGE_VERSION=v1.1.0

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

git clone https://github.com/dsblv/decamelize-keys.git && cd decamelize-keys
git checkout $PACKAGE_VERSION


npm install npm@6.14.5
npm install
sed -i -e 's/xo &&/ /g'  package.json
sed -i '1,2d' test.js
sed -i -e '1a var test = require("ava")\nvar fn = require("./")' test.js
npm test

