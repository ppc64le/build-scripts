# ----------------------------------------------------------------------------
#
# Package       : fflate
# Version       : 0.7.2
# Source repo   : https://github.com/101arrowz/fflate
# Tested on     : UBI: 8.3
# Language      : Typescript, Rust
# Travis-Check  : True-needs to verify
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -ex

WORK_DIR=`pwd`

PACKAGE_NAME=fflate
PACKAGE_VERSION=${1:-v0.7.2 }            
PACKAGE_URL=https://github.com/101arrowz/fflate

# install dependencies
yum install git python38 make gcc gcc-c++ -y

# install nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install v14.17.6

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# to install and build
npm install yarn -g
yarn install
yarn build 

# to execute tests
yarn test
echo "Tests Complete!"