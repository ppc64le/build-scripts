# !/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package        : babel
# Version        : v7.19.2
# Source repo    : https://github.com/babel/babel.git
# Tested on      : UBI 8.5
# Language       : Node
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=babel/babel
PACKAGE_VERSION="${1:-v7.19.2}"
PACKAGE_URL=https://github.com/babel/babel.git
NODE_VERSION=v16.17.0

cd $HOME
sudo yum install -y wget git gcc-c++ make && \
    wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    tar -C $HOME -xzf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    rm -rf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    npm install -g yarn

PATH=$HOME/node-$NODE_VERSION-linux-ppc64le/bin:$PATH

cd $HOME
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
make bootstrap
make
make test
