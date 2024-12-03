#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : isolated-vm
# Version       : v5.0.1
# Source repo   : https://github.com/laverdet/isolated-vm.git
# Tested on     : UBI: 9.3
# Language      : Javascript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pooja Shah <Pooja.Shah4@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=isolated-vm
PACKAGE_VERSION=${1:-v5.0.1}
PACKAGE_URL=https://github.com/laverdet/isolated-vm.git

yum install -y wget tar git gzip gcc gcc-c++ make python3 python3-devel glibc

export NODE_OPTIONS="--dns-result-order=ipv4first"

# Installing Nodejs 
export NODE_VERSION=18.20.5
wget -q https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-ppc64le.tar.gz
tar -xzf node-v$NODE_VERSION-linux-ppc64le.tar.gz
export PATH=$PWD/node-v$NODE_VERSION-linux-ppc64le/bin:$PATH
node -v

# Cloning repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! npm install --build-from-source ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

npm cache clean --force
export NODE_DISABLE_CACHE=1
# npm install segfault-handler

if ! npm --max-old-space-size=4096 test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi