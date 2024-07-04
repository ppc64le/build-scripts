#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	      : opentelemetry-collector-contrib
# Version	      : v0.102.0 
# Source repo	  : https://github.com/open-telemetry/opentelemetry-collector-contrib
# Tested on  	  : ubi:9.3
# Language        : GO
# Travis-Check    : True
# Script License  : Apache License 2.0
# Maintainer	  : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer      : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -ex

#variables
PACKAGE_NAME="opentelemetry-collector-contrib"
PACKAGE_VERSION=${1:-"v0.102.0"}
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-collector-contrib"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=`pwd`

export GO_VERSION=${GO_VERSION:-"1.22.1"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $3 "/" $4;}' <<<"$PACKAGE_URL" | xargs printf "%s" "$GOPATH")
export PACKAGE_SOURCE_ROOT

#install required dependencies
dnf install -qy wget git gcc-c++ make

# installing golang
wget https://go.dev/dl/go"$GO_VERSION".linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz


#cloning repository
cd $HOME_DIR
git clone "$PACKAGE_URL" 
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION" || exit 1
export GO111MODULE=on
export MAKEFLAGS="-j$(nproc)"
make -j$(nproc) gomoddownload
make install-tools

if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
