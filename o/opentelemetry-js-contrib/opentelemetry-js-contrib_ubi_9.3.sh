#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : opentelemetry-js-contrib
# Version          : resource-detector-container-v0.3.11
# Source repo      : https://github.com/open-telemetry/opentelemetry-js-contrib
# Tested on        : UBI:9.3
# Language         : Typescript
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=opentelemetry-js-contrib
PACKAGE_VERSION=${1:-resource-detector-container-v0.3.11}
PACKAGE_URL=https://github.com/open-telemetry/opentelemetry-js-contrib

export NODE_VERSION=${NODE_VERSION:-20}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y python3 python3-devel.ppc64le git gcc gcc-c++ libffi make
#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION


git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! npm ci ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi
npm run compile
if ! npm run test:ci:changed ; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi