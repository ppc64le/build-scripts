#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: github.com/maorfr/helm-plugin-utils
# Version	: v0.0.0-20200216074820-36d2fcf6ae86
# Source repo	: https://github.com/maorfr/helm-plugin-utils
# Language	: GO
# Travis-Check	: True
# Tested on	: UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/maorfr/helm-plugin-utils
PACKAGE_VERSION=${1:-v0.0.0-20200216074820-36d2fcf6ae86}
PACKAGE_URL=https://github.com/maorfr/helm-plugin-utils

yum install git gcc wget tar -y


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

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_Success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"
	exit 0
fi

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME*)

go mod init $PACKAGE_NAME
go mod tidy

# No test available for the package:
# OUTPUT:
# [root@d4b8a4988a52 helm-plugin-utils@v0.0.0-20200216074820-36d2fcf6ae86]# go test -v ./...
# ?       github.com/maorfr/helm-plugin-utils/pkg [no test files]
