#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: cacheable-request
# Version	: v7.01
# Source repo	: https://github.com/lukechilds/cacheable-request
# Tested on	: UBI 8.4
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {Sapana.Khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=cacheable-request
PACKAGE_VERSION=${1:-v7.0.2}
PACKAGE_URL=https://github.com/lukechilds/cacheable-request


yum -y update
yum -y install git wget gcc-c++ make curl python36 openssl openssl-devel
alias python=python3
ln -s /usr/bin/python3 /usr/bin/python

NODE_VERSION=v12.22.1
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install

npm test

exit 0

