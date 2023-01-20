#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package	      : kiali
# Version	      : v1.62.0
# Source repo	  : https://github.com/kiali/kiali
# Tested on	    : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	  : Shantanu Kadam <Shantanu.Kadam@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install dependencies
yum update -y && yum install -y gcc-c++ make python36 wget git tar zip npm
npm install -g yarn

## node setup
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 14
nvm use 14

BUILD_VERSION=v1.62.0

## go setup
wget https://go.dev/dl/go1.18.7.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.18.7.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go/
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Clone git repository
git clone https://github.com/kiali/kiali.git
cd kiali/
git checkout $BUILD_VERSION

# Build and test

## build: Runs `make go-check` internally and build Kiali binary
## test: Run tests, excluding third party tests under vendor and frontend
make clean build test

sed -i "97s/$/ --timeout 2m/" make/Makefile.build.mk
make lint-install
make lint

## build-ui: Runs the yarn commands to build the frontend UI
## build-ui-test: Runs the yarn commands to build the dev frontend UI and runs the UI tests
make clean-ui build-ui build-ui-test

echo "`date +'%d-%m-%Y %T'` - Build and Test Completed ---------------------------------------"
echo "- --------------------------------------------------------------------------------------"


