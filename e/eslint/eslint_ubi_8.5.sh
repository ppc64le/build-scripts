#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : eslint
# Version          : v8.30.0
# Source repo      : https://github.com/eslint/eslint.git
# Tested on        : UBI 8.5
# Language         : Javascript
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod.K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=v8.30.0
PACKAGE_NAME=eslint
PACKAGE_URL=https://github.com/eslint/eslint.git

WORKDIR=`pwd`
yum update -y
yum install git wget bzip2 gcc-c++ make python36 -y

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source ~/.nvm/nvm.sh
nvm install v16.17.1
nvm use v16.17.1

wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
mv phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin
rm -rf phantomjs-2.1.1-linux-ppc64.tar.bz2

cd $WORKDIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install

node Makefile mocha

