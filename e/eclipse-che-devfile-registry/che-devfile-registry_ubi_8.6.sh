#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : che-devfile-registry
# Version       : 7.63.0
# Source repo   : https://github.com/eclipse-che/che-devfile-registry.git
# Tested on     : UBI 8.6
# Language      : NODE
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=che-devfile-registry
PACKAGE_VERSION=${1:-7.63.0}
PACKAGE_URL=https://github.com/eclipse-che/che-devfile-registry.git

export NODE_VERSION=${NODE_VERSION:-v14}

yum install -y git 
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install "$NODE_VERSION"
npm install -g npm@8
npm install -g yarn 

yum -y install buildah

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! ./build.sh; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi