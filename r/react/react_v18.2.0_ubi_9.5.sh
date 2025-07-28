#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react
# Version       : 18.2.0
# Source repo   : https://github.com/facebook/react
# Tested on     : UBI 9.5 (ppc64le)
# Language      : Javascript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sanket Patil <Sanket.Patil11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


WORK_DIR=$(pwd)
REPO_URL=https://github.com/facebook/react
PACKAGE_NAME=react
MODULE_NAME=react
MODULE_NAME2=react-test-renderer
VERSION=${1:-v18.2.0}
NODE_VERSION=v14.17.6
  
dnf install -y git curl zlib-devel autoconf automake libtool gcc gcc-c++ make python3 python3-devel glibc-devel libpng-devel --allowerasing

export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

source "$NVM_DIR/nvm.sh"

nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

export PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"

cd "$WORK_DIR"
git clone "$REPO_URL"
cd "$PACKAGE_NAME"
git checkout "$VERSION"

sed -i '/"electron":/d' packages/react-devtools/package.json

npm install yarn -g

# Build
if ! CPPFLAGS='-DPNG_POWERPC_VSX_OPT=0' yarn install; then
  echo "----${PACKAGE_NAME}: Build Fail----"
else
  echo "----${PACKAGE_NAME}: Build Success----"
fi



# Run tests
# Run tests for react module
echo "----Running tests for react----"
if ! yarn test; then
  echo "----${MODULE_NAME}: Test Fail----"
  exit 2
else
  echo "----${MODULE_NAME}: Test Success----"
fi

# Run tests for react-test-renderer module
echo "----Running tests for react-test-renderer----"
if ! yarn test packages/react-test-renderer; then
  echo "----${MODULE_NAME2}: Test Fail----"
  exit 3
else
  echo "----${MODULE_NAME2}: Test Success----"
fi

echo "PASS: react and react-test-renderer version $VERSION built and tested successfully."
