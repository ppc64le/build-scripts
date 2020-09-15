#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : http-parser-js
# Version       : 0.4.5
# Source        : https://github.com/creationix/http-parser-js.git
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

PACKAGE_VERSION=0.4.5

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
        
git clone https://github.com/creationix/http-parser-js.git && cd http-parser-js
git checkout $PACKAGE_VERSION


npm install
sed -i -e 's/python/python2/g'  package.json
npm test

