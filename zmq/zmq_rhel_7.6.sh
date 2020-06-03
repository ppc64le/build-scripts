#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : zmq
# Version       : 2.15.3
# Source        : https://github.com/JustinTulloss/zeromq.node.git
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

PACKAGE_VERSION=2.15.3

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y openssl-devel.ppc64le curl git gcc-c++
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v12.16.1
if [ `nvm list | grep -c "v12.16.1"` -eq 0 ]
then
        nvm install v12.16.1
fi

nvm alias default v12.16.1

# add repo and install dev packages
cd /etc/yum.repos.d/
wget https://download.opensuse.org/repositories/network:messaging:zeromq:git-stable/RHEL_7/network:messaging:zeromq:git-stable.repo
sudo yum install zeromq-devel

# use npm@6.13.7
npm install -g npm@6.13.7

npm install -g node-gyp
npm install -g node-gyp

cd /root/
git clone https://github.com/JustinTulloss/zeromq.node.git
cd zeromq.node/
git checkout $PACKAGE_VERSION

node-gyp rebuild


npm install
npm test

