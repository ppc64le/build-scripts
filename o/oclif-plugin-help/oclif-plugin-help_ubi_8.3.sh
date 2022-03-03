#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : oclif/plugin-help
# Version       : v3.1.0
# Source repo   : https://github.com/oclif/plugin-help.git
# Tested on     : UBI: 8.3
# Language      : Node
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Srividya Chittiboina <Srividya.Chittiboina@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORK_DIR=`pwd`

PACKAGE_NAME=plugin-help
PACKAGE_VERSION=${1:-v3.1.0}
PACKAGE_URL=https://github.com/oclif/plugin-help.git

yum install git -y

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install v16.4.2

#clone repo
cd $WORK_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}

npm install yarn -g
yarn install
#yarn test
#50 passing (552ms) 1 pending(results are in parity with x86)