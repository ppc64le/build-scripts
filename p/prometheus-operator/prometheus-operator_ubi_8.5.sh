#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: prometheus-operator
# Version	: 7e176fda06cc
# Source repo	: https://github.com/coreos/prometheus-operator
# Tested on	: ubi 8.5
# Language      : GO
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="prometheus-operator"
PACKAGE_VERSION=${1:-"7e176fda06cc"}
PACKAGE_URL="https://github.com/coreos/prometheus-operator"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
ARCH="ppc64le"

export GO_VERSION=${GO_VERSION:-"1.15"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT="$GOPATH/src/github.com/coreos/"
export PACKAGE_SOURCE_ROOT

echo "installing dependencies from system repo"
dnf install -q -y wget zip make git gcc-c++ make

# installing golang
wget https://golang.org/dl/go"$GO_VERSION".linux-${ARCH}.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-${ARCH}.tar.gz
rm -f go"$GO_VERSION".linux-${ARCH}.tar.gz

mkdir -p "$PACKAGE_SOURCE_ROOT"
cd "$PACKAGE_SOURCE_ROOT"
git clone -q $PACKAGE_URL
cd "$PACKAGE_SOURCE_ROOT"/$PACKAGE_NAME
git checkout "$PACKAGE_VERSION"

if ! make build; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi


if ! make test-unit; then
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
