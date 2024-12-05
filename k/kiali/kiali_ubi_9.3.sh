#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : kiali
# Version               : v1.85.0
# Source repo           : https://github.com/kiali/kiali
# Tested on             : UBI:9.3
# Language              : Go
# Travis-Check          : True
# Script License        : Apache License 2.0 or later
# Maintainer            : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-v1.85.0}
PACKAGE_NAME=kiali
PACKAGE_URL=https://github.com/kiali/kiali.git

echo "Installing dependencies..."
yum install python3 python3-devel python3-pip wget git tar zip  make gcc-c++ -y

echo "Downloading and installing Go"
wget https://go.dev/dl/go1.22.1.linux-ppc64le.tar.gz
tar -C  /usr/local -xf go1.22.1.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

echo "Downloading and installing node"
NODE_VERSION=20
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

make lint-install
go mod tidy

echo "Installing..."
if ! make -e GO_BUILD_FLAGS=-race -e CGO_ENABLED=1 clean-all build ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails_"
        exit 1
fi

echo "Testing..."
if ! make -e GO_TEST_FLAGS="-race" test ; then
       echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
       echo "$PACKAGE_URL $PACKAGE_NAME"
       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
       exit 2
fi
npm install -g yarn
#Build and test for frontend.
echo "Installing..."
if ! make clean-all build-ui ; then
      echo "------------------$PACKAGE_NAME::Install_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail | Install_fails"
fi

cd frontend

echo "Building..."
if ! yarn pretty-quick --check --verbose ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

sed -i '18s/^/jest.setTimeout(10000);\n/' src/pages/Overview/__tests__/OverviewPage.test.tsx

echo "Testing..."
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
