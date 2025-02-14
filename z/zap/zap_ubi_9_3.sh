#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : zap
# Version       : v1.27.0
# Source repo   : https://github.com/uber-go/zap
# Tested on     : UBI: 9.3
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME="zap"
PACKAGE_URL="https://github.com/uber-go/zap"
PACKAGE_VERSION=${1:-"v1.27.0"}

export GO_VERSION=${GO_VERSION:-"1.21.9"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
export PACKAGE_SOURCE_ROOT="$GOPATH/src/go.uber.org"
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

echo "installing dependencies from system repo..."
dnf install -y gcc gcc-c++ wget git make 

#installing golang
wget "https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz"
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz

#clone the package
git clone -q $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME || exit 1
export GO111MODULE=on
git checkout "$PACKAGE_VERSION"

#building the package
if ! go mod tidy; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

#testing the package
if !(make test; make bench); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
