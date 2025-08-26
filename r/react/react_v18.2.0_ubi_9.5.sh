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
PACKAGE_URL="https://github.com/facebook/react"
PACKAGE_NAME="react"
MODULE_NAME="react"
MODULE_NAME2="react-test-renderer"
PACKAGE_VERSION="${1:-v18.2.0}"
NODE_VERSION="v14.17.6"
SCRIPT_PATH=$(dirname $(realpath $0))

# Install Dependencies
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

# Clone Repository
cd "$WORK_DIR"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# Applying patch file to skip 'electron' to build on ppc64le
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}_porting.patch

npm install yarn -g

# Build the Package
ret=0
CPPFLAGS='-DPNG_POWERPC_VSX_OPT=0' yarn install || ret=$?
if [ "$ret" -ne 0 ]; then
  echo "----${PACKAGE_NAME}: Build Fail----"
  exit 1
else
  echo "----${PACKAGE_NAME}: Build Success----"
fi

# Run tests for react
echo "----Running tests for ${MODULE_NAME}----"
yarn test || ret=$?
if [ "$ret" -ne 0 ]; then
  echo "----${MODULE_NAME}: Test Fail----"
  exit 2
else
  echo "----${MODULE_NAME}: Test Success----"
fi

# Run tests for react-test-renderer
echo "----Running tests for ${MODULE_NAME2}----"
yarn test packages/${MODULE_NAME2} || ret=$?
if [ "$ret" -ne 0 ]; then
  echo "----${MODULE_NAME2}: Test Fail----"
  exit 2
else
  echo "----${MODULE_NAME2}: Test Success----"
fi

echo "PASS: ${MODULE_NAME} and ${MODULE_NAME2} version ${PACKAGE_VERSION} built and tested successfully."
exit 0
