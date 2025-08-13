#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : lodash.memoize
# Version          : v4.1.9
# Source repo      : https://github.com/DefinitelyTyped/DefinitelyTyped
# Tested on        : UBI:9.5
# Language         : JavaScript,TypeScript 
# Travis-Check     : True
# Script License   : MIT License (standard permissive open‑source license)
# Maintainer       : Sai Vikram Kuppala <sai.vikram.kuppala@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
SCRIPT_PACKAGE_VERSION=4.1.9
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
DEFAULT_COMMIT_HASH="05766ab10a4987e93fdee7627f9fe9e7bc6d1a65"
COMMIT_HASH="${2:-${DEFAULT_COMMIT_HASH}}"
PACKAGE_NAME=DefinitelyTyped
PACKAGE_SUBDIR="types/lodash.memoize"
MODULE_NAME="lodash.memoize"
PACKAGE_URL=https://github.com/DefinitelyTyped/DefinitelyTyped
WORK_DIR=$(pwd)
# Enable Node.js stream and install system dependencies
yum module enable nodejs:20 -y
yum install -y git nodejs

# Install pnpm
npm install --global pnpm

# Clone the repository
cd "$WORK_DIR"
if [[ -d "$PACKAGE_NAME" ]]; then
  echo "Directory $PACKAGE_NAME already exists; pulling latest"
  cd "$PACKAGE_NAME"
else
  git clone "$PACKAGE_URL"
  cd "$PACKAGE_NAME"
fi
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
if ! pnpm test ${MODULE_NAME}; then
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