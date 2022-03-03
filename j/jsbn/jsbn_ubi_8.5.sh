#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jsbn
# Version       : v1.1.0,v0.1.1
# Source repo   : https://github.com/andyperlitch/jsbn
# Tested on	: UBI 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vathsala . <vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jsbn
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v1.1.0}
PACKAGE_URL=https://github.com/andyperlitch/jsbn

export NODE_VERSION=${NODE_VERSION:-v12.22.4}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git jq

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

nvm install "$NODE_VERSION"
npm install -g npm@latest

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi
 

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 0
fi
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
PACKAGE_VERSION=$(jq -r ".version" package.json)
if ! npm install && npm audit fix && npm audit fix --force; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi
# Tests not available(Test N/A).
