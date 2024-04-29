#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react-grid-layout
# Version       : 1.4.1
# Source repo   : https://github.com/STRML/react-grid-layout
# Tested on     : UBI9.3
# Language      : Node
# Travis-Check  : True
# Script License: MIT License
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Exit immediately if a command exits with a non-zero status.
set -e

PACKAGE_NAME=react-grid-layout
PACKAGE_VERSION=${1:-1.4.1}
PACKAGE_URL=https://github.com/STRML/react-grid-layout

yum update -yq && yum install -yq git make

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

nvm install 18
export NODE_OPTIONS="--dns-result-order=ipv4first"
npm i --global yarn

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# install deps
if ! yarn; then
    echo "yarn dependency installation failed"
    exit 1
fi

# Build
if echo "Starting BUILD..." && ! yarn build; then
    echo "!!    BUILD FAILED    !!"
    exit 1
elif echo "Starting TESTS..." && ! yarn test; then
    echo "!!    TESTS FAILED    !!"
    exit 1
else
    echo "!!    BUILD & TESTS SUCCESSFUL    !!"
fi

