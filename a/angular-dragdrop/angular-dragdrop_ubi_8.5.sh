#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : angular-dragdrop
# Version          : 1.2.2
# Source repo      : https://github.com/angular-dragdrop/angular-dragdrop
# Tested on        : RHEL 8.5,UBI 8.5
# Language         : Node
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vikas Kumar <kumar.vikas@in.ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=angular-dragdrop
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-1.2.2}
PACKAGE_URL=https://github.com/angular-dragdrop/angular-dragdrop.git

yum install -y yum-utils git jq

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 1
fi

cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION" || exit 1

if ! npm install; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

# Test failure is in parity with Intel.
if ! npm test; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi

# Output:
# fs.js:36
# } = primordials;
    # ^

# ReferenceError: primordials is not defined
    # at fs.js:36:5
    # at req_ (/angular-dragdrop/node_modules/natives/index.js:143:24)
    # at Object.req [as require] (/angular-dragdrop/node_modules/natives/index.js:55:10)
    # at Object.<anonymous> (/angular-dragdrop/node_modules/graceful-fs/fs.js:1:37)
    # at Module._compile (internal/modules/cjs/loader.js:999:30)
    # at Object.Module._extensions..js (internal/modules/cjs/loader.js:1027:10)
    # at Module.load (internal/modules/cjs/loader.js:863:32)
    # at Function.Module._load (internal/modules/cjs/loader.js:708:14)
    # at Module.require (internal/modules/cjs/loader.js:887:19)
    # at require (internal/modules/cjs/helpers.js:74:18)
# npm ERR! Test failed.  See above for more details.
