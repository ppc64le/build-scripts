#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : uniq
# Version       : master(4e0fc2c02bfdc17141301845c885f21b9fdacc21)
# Source        : https://github.com/mikolalysenko/uniq.git
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

PACKAGE_VERSION=4e0fc2c02bfdc17141301845c885f21b9fdacc21

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

git clone https://github.com/mikolalysenko/uniq.git && cd uniq
git checkout $PACKAGE_VERSION

sed -i -e 's/\[2,1\]/\[1,2\]/g' test/test.js

npm install
npm test

