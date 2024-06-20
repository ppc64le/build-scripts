#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package          : caterpillar
# Version          : v6.8.0
# Source repo      : https://github.com/bevry/caterpillar
# Tested on        : RHEL 8.5,UBI 8.5
# Language         : Node
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Saraswati Patra <Saraswati.Patra@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=caterpillar
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v6.8.0}
PACKAGE_URL=https://github.com/bevry/caterpillar
yum install -y yum-utils git jq

NODE_VERSION=v14.4.0
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi
 

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 1
fi

cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
#npm install --save-dev mocha
if ! npm install && npm audit fix && npm audit fix --force; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

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

# Build passed and Test is in parity with intel
#Error: Cannot find module '/caterpillar/edition-es2019/test.js'
#    at Function.Module._resolveFilename (internal/modules/cjs/loader.js:1029:15)
#    at Function.Module._load (internal/modules/cjs/loader.js:898:27)
#    at Function.executeUserEntryPoint [as runMain] (internal/modules/run_main.js:71:12)
#    at internal/main/run_main_module.js:17:47 {
#  code: 'MODULE_NOT_FOUND',
#  requireStack: []
#}
#npm ERR! Test failed.  See above for more details.
#------------------caterpillar:install_success_but_test_fails---------------------
#https://github.com/bevry/caterpillar caterpillar
#caterpillar  |  https://github.com/bevry/caterpillar | v6.8.0 | "Red Hat Enterprise Linux 8.5 (Ootpa)" | GitHub | Fail |  Install_success_but_test_Fails


