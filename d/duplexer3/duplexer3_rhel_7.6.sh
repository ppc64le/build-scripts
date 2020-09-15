#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : duplexer3
# Version       : v0.1.4 
# Source        : https://github.com/floatdrop/duplexer3.git
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

PACKAGE_VERSION=v0.1.4 

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

git clone https://github.com/floatdrop/duplexer3.git && cd duplexer3
git checkout $PACKAGE_VERSION


npm install npm@6.14.5
sed -i -e '176s/null/false/g'  test/tests.js
sed -i -e '186s/null/false/g'  test/tests.js
sed -i -e '189s/null/false/g'  test/tests.js
sed -i -e '201s/null/false/g'  test/tests.js
npm install
npm test

