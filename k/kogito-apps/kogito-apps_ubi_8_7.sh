#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : kiegroup
# Version       : 1.36.1.Final
# Source repo   : https://github.com/kiegroup/kogito-apps.git
# Tested on     : UBI 8.7
# Language      : JAVA
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhimrao Patil <Bhimrao.Patil@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------
set -e
export NODE_OPTIONS="--dns-result-order=ipv4first"

PACKAGE_NAME=kogito-apps
PACKAGE_VERSION=${1:-1.36.1.Final}
PACKAGE_URL=https://github.com/kiegroup/kogito-apps.git

yum install -y git curl
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install v18.12.0
ln -s $HOME/.nvm/versions/node/v18.12.0n/bin/node /usr/bin/node
ln -s $HOME/.nvm/versions/node/v18.12.0n/bin/npm /usr/bin/npm

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
	rm -rf $PACKAGE_NAME
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
	exit 0
fi

cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

cd ui-packages/
yum install npm -y
npm install -g yarn
yarn install
yarn run init
export NODE_OPTIONS=--openssl-legacy-provider

if ! yarn run build:prod; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! yarn test -u; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi
