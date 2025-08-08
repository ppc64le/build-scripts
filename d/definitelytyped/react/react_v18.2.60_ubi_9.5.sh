#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : react
# Version          : v18.2.60
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
SCRIPT_PACKAGE_VERSION=18.2.60
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
DEFAULT_COMMIT_HASH="bda68a6d19efbc1cf3465e75f68e31355be5ac39"
COMMIT_HASH="${2:-${DEFAULT_COMMIT_HASH}}"
PACKAGE_NAME=DefinitelyTyped
PACKAGE_SUBDIR="types/react/v18"
PACKAGE_URL=https://github.com/DefinitelyTyped/DefinitelyTyped


# Enable Node.js stream and install system dependencies
yum module enable nodejs:20 -y
yum install -y git nodejs

# Install pnpm
npm install --global pnpm

# Clone the repository
if [[ -d "$PACKAGE_NAME" ]]; then
  echo "Directory $PACKAGE_NAME already exists; pulling latest"
  cd "$PACKAGE_NAME"
else
  git clone "$PACKAGE_URL"
  cd "$PACKAGE_NAME"
fi
git checkout "$COMMIT_HASH"
# Install only our target package
if ! (npm i @types/react@$PACKAGE_VERSION && npm fund); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_SUBDIR | GitHub | Fail |  Install_Fails"
        exit 1
fi
#Run test cases

if ! pnpm --filter ".$PACKAGE_SUBDIR..." test ; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_SUBDIR | GitHub | Fail |  Install_success_but_test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_SUBDIR | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi