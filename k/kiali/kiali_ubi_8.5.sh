#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	: kiali
# Version	: v1.62.0
# Source repo	: https://github.com/kiali/kiali
# Tested on	: UBI 8.5
# Language   	: Go
# Travis-Check  : True
# Script License: Apache License 2.0 or later
# Maintainer	: Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-v1.62.0}
PACKAGE_NAME=kiali
PACKAGE_URL=https://github.com/kiali/kiali.git

yum update -y && yum install -y gcc-c++ make python36 wget git tar zip npm
npm install -g yarn

# Install go
wget https://go.dev/dl/go1.18.7.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.18.7.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go/
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Node setup
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 14
nvm use 14

# Clone git repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

sed -i "97s/$/ --timeout 6m/" make/Makefile.build.mk
#Build and test for backend
make lint-install
make lint
#build
make -e GO_BUILD_FLAGS=-race -e CGO_ENABLED=1 clean-all build
make -e GO_TEST_FLAGS="-race" test

#Build and test for frontend
make clean-all build-ui

cd frontend
yarn pretty-quick --check --verbose 
yarn test --watchAll=false



