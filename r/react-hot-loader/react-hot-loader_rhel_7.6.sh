#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : react-hot-loader
# Version       : v4.12.19
# Source        : https://github.com/gaearon/react-hot-loader.git
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

PACKAGE_VERSION=v4.12.19

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

git clone https://github.com/gaearon/react-hot-loader.git && cd react-hot-loader
git checkout $PACKAGE_VERSION


npm install npm@6.14.5

npm install
sed -i -e '6s/.\/dist\/react-hot-loader.production.min.js/.\/src\/index.prod.js/g' index.js
sed -i '14,17d' test/hot/react-dom.integration.spec.js 
npm run test:es2015

