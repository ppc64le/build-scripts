#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package	: lz4
# Version	: v2.5.2, v1.0.1, v2.4.0
# Source repo	: https://github.com/pierrec/lz4
# Tested on	: ubi 8.3, 8.5
# Language      : GO
# Travis-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com> / Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="lz4"
PACKAGE_URL="https://github.com/pierrec/lz4"
PACKAGE_VERSION=${1:-"v2.5.2"}
export GO_VERSION=${GO_VERSION:-"1.16"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export GO111MODULE=off
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
export PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $3 "/" $4;}' <<<$PACKAGE_URL | xargs printf "%s" $GOPATH)
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# steps to clean up the PKG installation
if [ "$1" = "clean" ]; then
    rm -rf $GOROOT
    rm -rf $GOPATH
    exit 0
fi

echo "installing dependencies from system repo"
dnf install -y gcc gcc-c++ wget curl-devel git -y >/dev/null

# installing golang
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

mkdir -p $PACKAGE_SOURCE_ROOT
cd $PACKAGE_SOURCE_ROOT
git clone https://github.com/pierrec/xxHash
cd xxHash
git checkout v0.1.5
go install ./...

cd $PACKAGE_SOURCE_ROOT
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd $PACKAGE_SOURCE_ROOT/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! go install ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! go test -v -cpu=2 && go test -v -cpu=2 -race; then
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
