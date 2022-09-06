#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package          : hard-source-webpack-plugin
# Version          : v0.13.1
# Source repo      : https://github.com/mzgoddard/hard-source-webpack-plugin
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

PACKAGE_NAME=hard-source-webpack-plugin
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v0.13.1}
PACKAGE_URL=https://github.com/mzgoddard/hard-source-webpack-plugin
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
#[hardsource:c0acc6b1] Last compilation did not finish saving. Building new cache.
#    ✓ builds changes in serializer-append-2-base-1dep-bad-cache fixture


#  256 passing (2m)
#  7 pending

#------------------hard-source-webpack-plugin:install_&_test_both_success-------------------------
#https://github.com/mzgoddard/hard-source-webpack-plugin hard-source-webpack-plugin
#hard-source-webpack-plugin  |  https://github.com/mzgoddard/hard-source-webpack-plugin | v0.13.1 | "Red Hat Enterprise Linux 8.5 (Ootpa)" | GitHub  | Pass |  Both_Install_and_Test_Success
