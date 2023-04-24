#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : che-incubator/devfile-converter
# Version       : main
# Source repo   : https://github.com/che-incubator/devfile-converter.git
# Tested on     : UBI 8.7
# Language      : Node
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

echo "node-options=--max_old_space_size=4096" >> ~/.npmrc
echo "alias npm='node --dns-result-order=ipv4first /usr/bin/npm'" >> ~/.bashrc

PACKAGE_NAME=devfile-converter
PACKAGE_VERSION=${1:-main}
PACKAGE_URL=https://github.com/che-incubator/devfile-converter.git

yum install -y git curl

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install v18.12.0
ln -s $HOME/.nvm/versions/node/v18.12.0/bin/node /usr/bin/node
ln -s $HOME/.nvm/versions/node/v18.12.0/bin/npm /usr/bin/npm

yum install npm -y
npm install -g yarn

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

yarn 

if ! yarn run build; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! yarn test; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi
