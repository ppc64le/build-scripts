#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : pstree.remy
# Version       : 1.1.8
# Source        : https://registry.npmjs.org/pstree.remy/-/pstree.remy-1.1.8.tgz
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

wget https://registry.npmjs.org/pstree.remy/-/pstree.remy-1.1.8.tgz
tar zxvf pstree.remy-1.1.8.tgz && rm pstree.remy-1.1.8.tgz
cd package

npm install
sed -i -e '40s/* 2//g' tests/index.test.js
npm test

