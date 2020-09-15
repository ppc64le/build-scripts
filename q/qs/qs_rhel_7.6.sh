#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : qs
# Version       : v6.7.0
# Source        : https://github.com/ljharb/qs.git
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

PACKAGE_VERSION=v6.7.0

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

git clone https://github.com/ljharb/qs.git && cd qs/
git checkout $PACKAGE_VERSION

npm install -g npm@6
npm install gulp

sed -i "133d" test/utils.js
sed -i -e "132a \ \ \ \ var buffer = Buffer.from('abc');" test/utils.js

npm install
npm test
