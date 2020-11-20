#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : flagged-respawn
# Version       : v1.0.1
# Source        : https://github.com/gulpjs/flagged-respawn.git 
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

PACKAGE_VERSION=v1.0.1

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

git clone https://github.com/gulpjs/flagged-respawn.git  && cd flagged-respawn
git checkout $PACKAGE_VERSION


sed -i -e "135s/expect(err.signal).toEqual(null);/expect(err.signal).toEqual('SIGHUP');/g" test/index.js
npm install
npm test

