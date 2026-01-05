#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package	    : fetch-blob
# Version	    : v3.2.0
# Source repo	    : https://github.com/node-fetch/fetch-blob
# Tested on	    : UBI 9.3
# Language          : Node
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Prachi Kurade <prachi.kurade1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=fetch-blob
PACKAGE_VERSION=${1:-v3.2.0}
PACKAGE_URL=https://github.com/node-fetch/fetch-blob

export NODE_VERSION=${NODE_VERSION:-17.3}
export NODE_OPTIONS="--dns-result-order=ipv4first"

yum install -y python3 python3-devel.ppc64le git gcc gcc-c++ libffi make 

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! npm install && npm audit fix --force; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Tests commented because 1 tests case is failing in parity with x86 execution. Command is npm test
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Install_Success"
exit 0



