#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : conftest
# Version       : v0.30.0
# Source repo   : https://github.com/open-policy-agent/conftest
# Language      : GO
# Travis-Check  : True
# Tested on     : UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.

PACKAGE_NAME=conftest
PACKAGE_VERSION=${1:-v0.30.0}
PACKAGE_URL=https://github.com/open-policy-agent/conftest

yum install wget git gcc make -y

curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    && dnf install -y epel-release-latest-8.noarch.rpm \
    && rm -f epel-release-latest-8.noarch.rpm

yum install -y bats

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

#Build and test the package
git clone $PACKAGE_URL -b $PACKAGE_VERSION
cd $PACKAGE_NAME
if ! make build ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make test || ! make test-acceptance ; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
fi

#Create the artifacts (.rpm, .deb, tar.gz)
go install github.com/goreleaser/goreleaser@latest
sed -i '/^  goarch:/a\  - ppc64le' .goreleaser.yml
goreleaser release --snapshot --rm-dist
