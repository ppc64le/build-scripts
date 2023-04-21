#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : d3-random
# Version          : v3.0.1
# Source repo      : https://github.com/d3/d3-random
# Tested on        : UBI 8.7
# Language         : Javascript
# Travis-Check     : True
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

PACKAGE_NAME=d3-random
PACKAGE_VERSION=${1:-v3.0.1}
PACKAGE_URL=https://github.com/d3/d3-random
HOME_DIR=${PWD}

yum install -y yum-utils git wget tar gzip

#Installing Nodejs v14.21.2
cd $HOME_DIR
wget https://nodejs.org/dist/v14.21.2/node-v14.21.2-linux-ppc64le.tar.gz
tar -xzf node-v14.21.2-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v14.21.2-linux-ppc64le/bin:$PATH
node -v
npm -v

#yarn installation
npm install -g yarn

#Cloning d3 repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Install dependencies from package.json

if ! yarn --frozen-lockfile ; then
      echo "------------------$PACKAGE_NAME::Install_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail | Install_fails"
fi

if ! yarn run eslint src test --format=compact ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

if ! yarn test ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi
