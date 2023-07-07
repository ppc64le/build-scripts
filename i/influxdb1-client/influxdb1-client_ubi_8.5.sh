#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: influxdb1-client
# Version	: v0.0.0-20191209144304-8bf82d3c094d
# Source repo	: https://proxy.golang.org/github.com/influxdata/influxdb1-client/@v/v0.0.0-20191209144304-8bf82d3c094d.zip
# Tested on	: ubi 8.5
# Language      : GO
# Travis-Check  : True
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

PACKAGE_NAME="influxdb1-client"
PACKAGE_VERSION=${1:-"v0.0.0-20191209144304-8bf82d3c094d"}
PACKAGE_URL="https://proxy.golang.org/github.com/influxdata/influxdb1-client/@v/$PACKAGE_VERSION.zip"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

export GO_VERSION=${GO_VERSION:-"1.13"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $4 "/" $5 "/";}' <<<"$PACKAGE_URL" | xargs printf "%s" "$GOPATH")
export PACKAGE_SOURCE_ROOT

echo "installing dependencies from system repo"
dnf install -q -y wget zip gcc-c++


echo "installing golang $GO_VERSION"
wget -q https://golang.org/dl/go"$GO_VERSION".linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz

wget $PACKAGE_URL
echo "$PACKAGE_SOURCE_ROOT"
mkdir -p "$PACKAGE_SOURCE_ROOT"
unzip -q ./*.zip -d "$GOPATH"/src
cd "$PACKAGE_SOURCE_ROOT"
mv $PACKAGE_NAME* $PACKAGE_NAME
cd $PACKAGE_NAME
go get ./...

if ! go install ./...; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! go test ./...; then
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
