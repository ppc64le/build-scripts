#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package: jquery-once
# Version: 2.2.3
# Source repo: https://github.com/RobLoach/jquery-once
# Tested on: RHEL v8.5
# Language: PHP
# Travis-Check: True
# Script License: Apache License, Version 2 or later
# Maintainer: Prashant Khoje <prashant.khoje@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex
PACKAGE_NAME=jquery-once
PACKAGE_VERSION=${1:-2.2.3}
PACKAGE_URL="https://github.com/RobLoach/jquery-once"

dnf install -y git wget
DISTRO=linux-ppc64le

cd $HOME
# Install nodejs
NODE_VERSION=v18.0.0
wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$DISTRO.tar.gz
tar -xzf node-$NODE_VERSION-$DISTRO.tar.gz
export PATH=$HOME/node-$NODE_VERSION-$DISTRO/bin:$PATH
rm -f node-$NODE_VERSION-$DISTRO.tar.gz

node --version

cd $HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
npm install
npm run build
npm test
