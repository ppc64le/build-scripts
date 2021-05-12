#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : trim-newlines
# Version       : v3.0.0
# Source        : https://github.com/sindresorhus/trim-newlines.git
# Tested on     : RHEL 7.6
# Node Version  : v12.19.1
# Maintainer    : Sudeep Raj <sudeep.raj2@ibm.com>
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

PACKAGE_VERSION=v3.0.0

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y openssl-devel.ppc64le curl git
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v12.19.1
if [ `nvm list | grep -c "v12.19.1"` -eq 0 ]
then
        nvm install v12.19.1
fi

nvm alias default v12.19.1

git clone https://github.com/sindresorhus/trim-newlines.git && cd trim-newlines/
git checkout $PACKAGE_VERSION

npm install

npm test



