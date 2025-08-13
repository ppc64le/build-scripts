#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : react-test-renderer
# Version          : v18
# Source repo      : https://github.com/DefinitelyTyped/DefinitelyTyped
# Tested on        : UBI:9.5
# Language         : JavaScript,TypeScript 
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sai Vikram Kuppala <sai.vikram.kuppala@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

SCRIPT_PACKAGE_VERSION=18.0.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
DEFAULT_COMMIT_HASH="1e0850cea1973225d2fde4c388f01e16009cc255"
COMMIT_HASH="${2:-${DEFAULT_COMMIT_HASH}}"
PACKAGE_NAME="DefinitelyTyped"
PACKAGE_SUBDIR="types/react-test-renderer/v18"
MODULE_NAME="react-test-renderer"
PACKAGE_URL="https://github.com/DefinitelyTyped/DefinitelyTyped"
WORK_DIR=$(pwd)

# --- Install Dependencies ---
# Enable Node.js stream and install system dependencies.
echo "----Installing system dependencies...----"
yum module enable nodejs:20 -y
yum install -y git nodejs

# Install pnpm globally using npm
echo "----Installing pnpm...----"
npm install --global pnpm

# --- Clone Repository ---
cd "$WORK_DIR"
if [ ! -d "$PACKAGE_NAME" ]; then
  echo "----Cloning repository: $PACKAGE_URL----"
  git clone "$PACKAGE_URL"
  cd "$PACKAGE_NAME"
else
  echo "----Directory $PACKAGE_NAME already exists, checking out new commit.----"
  cd "$PACKAGE_NAME"
fi

# Checkout the specified commit hash
git checkout "$COMMIT_HASH"

# --- Build the Package ---
ret=0
echo "----Building the package: $PACKAGE_SUBDIR----"
if ! pnpm install -w --filter "./${PACKAGE_SUBDIR}..."; then
  echo "----${PACKAGE_NAME}: Build Fail----"
  ret=1
fi

if [ "$ret" -ne 0 ]; then
  echo "----${PACKAGE_NAME}: Build Fail----"
  exit 1
else
  echo "----${PACKAGE_NAME}: Build Success----"
fi

# --- Run Tests ---
echo "----Running tests for ${MODULE_NAME}----"
if ! pnpm test react-test-renderer/v18; then
  echo "----${MODULE_NAME}: Test Fail----"
  ret=2
fi

if [ "$ret" -ne 0 ]; then
  echo "----${MODULE_NAME}: Test Fail----"
  exit 2
else
  echo "----${MODULE_NAME}: Test Success----"
fi

echo "PASS: ${MODULE_NAME} version ${PACKAGE_VERSION} built and tested successfully."
exit 0
