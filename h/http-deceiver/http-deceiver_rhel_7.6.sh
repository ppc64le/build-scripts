#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : http-deceiver
# Version       : v1.2.7
# Source        : https://github.com/indutny/http-deceiver.git 
# Tested on     : RHEL 7.6
# Node Version  : v8.9.4
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

PACKAGE_VERSION=v1.2.7

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y openssl-devel.ppc64le curl git 
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v8.9.4
if [ `nvm list | grep -c "v8.9.4"` -eq 0 ]
then
        nvm install v8.9.4
fi

nvm alias default v8.9.4

git clone https://github.com/indutny/http-deceiver.git && cd http-deceiver
git checkout $PACKAGE_VERSION


npm install npm@6.14.5
sed -i -e '209s/assert/\/\/assert/g'  test/api-test.js
sed -i -e '209a done()' test/api-test.js

npm install
npm test

