#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package          : ast-types
# Version          : master
# Source repo      : https://github.com/benjamn/ast-types.git
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

PACKAGE_NAME=ast-types
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/benjamn/ast-types.git

yum -y install git wget gcc-c++ make python2 curl

NODE_VERSION=v12.22.4
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

if ! npm install --legacy-peer-deps; then
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

# install_&_test_both_success mentioned version.
 #Whole-program validation for Babel TypeScript tests
 #  ✔ should validate test/data/babel-parser/test/fixtures/typescript/class/async-optional-method/input.js
 #  ✔ should validate test/data/babel-parser/test/fixtures/typescript/class/optional-async-error/input.js
  # ✔ should validate test/data/babel-parser/test/fixtures/typescript/expect-plugin/export-interface/input.js
  #✔ should validate test/data/babel-parser/test/fixtures/typescript/expect-plugin/export-type-named/input.js
  #✔ should validate test/data/babel-parser/test/fixtures/typescript/expect-plugin/export-type/input.js
  #✔ should validate test/data/babel-parser/test/fixtures/typescript/scope/module-declaration-var-2/input.js
  #✔ should validate test/data/babel-parser/test/fixtures/typescript/scope/module-declaration-var/input.js


  #229 passing (22s)

#------------------ast-types:install_&_test_both_success-------------------------
#https://github.com/benjamn/ast-types.git ast-types
#ast-types  |  https://github.com/benjamn/ast-types.git | master | "Red Hat Enterprise Linux 8.5 #(Ootpa)" | GitHub  | Pass |  Both_Install_and_Test_Success
#[root@4dfd545f6640 /]#

