#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package          : is-natural-number
# Version          : master
# Source repo      : https://github.com/shinnn/is-natural-number.js
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

PACKAGE_NAME=is-natural-number
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/shinnn/is-natural-number.js
yum install -y yum-utils git jq
NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION
#npm install n -g && n latest && npm install -g npm@latest

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
#npm install -g yarn
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

#[root@14a442fd4a73 is-natural-number.js]# git checkout master
#Previous HEAD position was a19fa22 release v4.0.1
#Switched to branch 'master'
#Your branch is up to date with 'origin/master'.
#[root@14a442fd4a73 is-natural-number.js]# npm install
#up to date in 3.353s
#[root@14a442fd4a73 is-natural-number.js]# npm test

#> is-natural-number@4.0.1 pretest /is-natural-number.js
#> eslint --config @shinnn --ignore-path .gitignore .


#> is-natural-number@4.0.1 test /is-natural-number.js
#> node --throw-deprecation --track-heap-objects test.js | tap-dot


#  ................................................................................................

#  3 tests
#  96 passed

#  Pass!
