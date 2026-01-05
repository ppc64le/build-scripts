#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react-native-netinfo
# Version       : v11.3.2
# Source repo   : https://github.com/react-native-netinfo/react-native-netinfo.git
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript
# Ci-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="react-native-netinfo"
PACKAGE_VERSION="v11.3.2"
PACKAGE_URL="https://github.com/react-native-netinfo/react-native-netinfo.git"
WORK_DIR=$(pwd)
RUNTESTS=1

for arg in "$@"; do
  case "$arg" in
    --skip-tests)
      RUNTESTS=0
      echo "INFO: Tests will be skipped."
      shift
      ;;
    -*|--*)
      echo "Unknown option: $arg"
      exit 3
      ;;
    *)
      PACKAGE_VERSION="$arg"
      echo "INFO: Using version: $PACKAGE_VERSION"
      ;;
  esac
done

yum install -y git

# Install NVM + Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

nvm install 20
nvm alias default 20
nvm use 20

# Install yarn package manager
npm install -g yarn

# Clone the repo
cd "$WORK_DIR"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# Install dependencies
yarn install

# Build the project
ret=0
yarn prepare || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Build failed."
    exit 1
else
    echo "INFO: $PACKAGE_NAME - Build successful."
fi

# Install the package
echo "Installing $PACKAGE_NAME"
PACKAGE_TGZ_NAME="${PACKAGE_NAME}.tgz"
yarn pack --filename "$PACKAGE_TGZ_NAME"
npm install -g "$(realpath "$PACKAGE_TGZ_NAME")" || ret=$?

if [ $? -eq 0 ]; then
  echo "$PACKAGE_NAME $PACKAGE_VERSION installed successfully."
else
  echo "Installation failed."
  exit 3
fi

# Skip tests
if [ "$RUNTESTS" -eq 0 ]; then
    echo "INFO: $PACKAGE_NAME build and install successful. Tests were skipped."
    exit 0
fi

# Run tests
yarn test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Test phase failed."
    exit 2
else
    echo "INFO: $PACKAGE_NAME - All tests passed."
fi

# Final Success
PACKAGE_BUILD_VERSION=$(node -e "console.log(require('./package.json').version)")
if [[ "$PACKAGE_BUILD_VERSION" == "${PACKAGE_VERSION#v}" ]]; then
    echo "SUCCESS: $PACKAGE_NAME version $PACKAGE_BUILD_VERSION built and tested successfully."
    exit 0
else
    echo "WARNING: Version mismatch. Expected ${PACKAGE_VERSION#v}, got $PACKAGE_BUILD_VERSION."
    exit 2
fi
    exit 2
fi
