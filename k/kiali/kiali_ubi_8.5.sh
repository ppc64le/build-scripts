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

yum update -y && yum install -y gcc-c++ make python38 wget git tar zip 

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


make lint-install
make lint

#Build and test for backend.
if ! make -e GO_BUILD_FLAGS=-race -e CGO_ENABLED=1 clean-all build ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails_"
        exit 1
fi

if ! make -e GO_TEST_FLAGS="-race" test ; then
       echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
       echo "$PACKAGE_URL $PACKAGE_NAME"
       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
       exit 2
fi
npm install -g yarn
#Build and test for frontend.
if ! make clean-all build-ui ; then
      echo "------------------$PACKAGE_NAME::Install_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail | Install_fails"
fi

cd frontend

if ! yarn pretty-quick --check --verbose ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi
if ! yarn test --watchAll=false ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi




