#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: go-oidc
# Version	: v2.1.0, v0.0.0-20180117170138-065b426bd416
# Source repo	: https://github.com/coreos/go-oidc.git
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Reynold Vaz <Reynold.Vaz@ibm.com>/ Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#required to include --security-opt seccomp=unconfined in docker command

PACKAGE_NAME=go-oidc
PACKAGE_VERSION=${1:-v2.1.0}
PACKAGE_URL=https://github.com/coreos/go-oidc.git

PACKAGE_COMMIT_HASH=`echo $PACKAGE_VERSION | cut -d'-' -f3`

yum install go git -y

export GOPATH=/home/tester/go
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

mkdir -p $GOPATH/src/github.com/coreos && cd $GOPATH/src/github.com/coreos
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_COMMIT_HASH

if ! go mod init; then
        echo "------------------$PACKAGE_NAME:initialize_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Initialize_Fails"
        exit 1
fi

#To upgrade to the versions selected by go 1.16
if ! go mod tidy -go=1.16 && go mod tidy -go=1.17; then
        echo "------------------$PACKAGE_NAME:dependency_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Dependency_Fails"
        exit 1
fi

if ! go install ./...; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
        exit 1
fi

if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Build_and_Test_Success"
        exit 0
fi

