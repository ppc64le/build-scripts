#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: go-oidc
# Version	: v2.1.0
# Source repo	: https://github.com/coreos/go-oidc.git
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Reynold Vaz <Reynold.Vaz@ibm.com>
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

yum install go git -y

export GOPATH=/home/tester/go
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

mkdir -p $GOPATH/src/github.com/coreos && cd $GOPATH/src/github.com/coreos
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go get -u golang.org/x/lint/golint
cp /home/tester/go/bin/golint /usr/bin
go get -v -t github.com/coreos/go-oidc/...
go get golang.org/x/tools/cmd/cover

go mod init
go mod tidy

if ! ./test ; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi