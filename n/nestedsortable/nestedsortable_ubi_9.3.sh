#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : nestedSortable
# Version          : master
# Source repo      : https://github.com/ilikenwf/nestedSortable
# Tested on        : UBI:9.3
# Language         : Node
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=nestedSortable
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/ilikenwf/nestedSortable

export NODE_VERSION=${NODE_VERSION:-18}
yum install -y git gcc gcc-c++ make

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION


git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! npm install && npm audit fix --force; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
	echo "------------------$PACKAGE_NAME:install_success-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Install_Success"
    exit 0
fi

#Since there are no tests for this, ignoring test command

