#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : webpack-hot-middleware-example
# Version       : 1.0.0
# Source        : https://registry.npmjs.org/webpack-hot-middleware-example/-/webpack-hot-middleware-example-1.0.0.tgz
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
sudo yum install -y java-1.8.0-openjdk

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y openssl-devel.ppc64le curl wget tar git 
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v12.16.1
if [ `nvm list | grep -c "v12.16.1"` -eq 0 ]
then
        nvm install v12.16.1
fi

nvm alias default v12.16.1


git clone  https://github.com/webpack-contrib/webpack-hot-middleware.git
cd webpack-hot-middleware/
npm install .
cd ..

wget https://registry.npmjs.org/webpack-hot-middleware-example/-/webpack-hot-middleware-example-1.0.0.tgz
tar -xvzf webpack-hot-middleware-example-1.0.0.tgz
cd package/
sed -i "12d" ./package.json
sed -i -e '11a "webpack-hot-middleware": "./../webpack-hot-middleware/"' ./package.json

npm install .
#npm test

npm config set unsafe-perm true

