#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : gensync
# Version       : 1.0.0-beta.1
# Source        : https://registry.npmjs.org/gensync/-/gensync-1.0.0-beta.1.tgz
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



#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y openssl-devel.ppc64le curl git wget
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v12.16.1
if [ `nvm list | grep -c "v12.16.1"` -eq 0 ]
then
        nvm install v12.16.1
fi

nvm alias default v12.16.1

wget https://registry.npmjs.org/gensync/-/gensync-1.0.0-beta.1.tgz
tar zxvf gensync-1.0.0-beta.1.tgz && rm gensync-1.0.0-beta.1.tgz
cd package

npm install
sed -i -e '93s/options.url/"https:\/\/localhost\/"/g' node_modules/jsdom/lib/jsdom/browser/Window.js
npm test

