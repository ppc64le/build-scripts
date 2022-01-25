# -----------------------------------------------------------------------------
#
# Package	: github.com/shopify/logrus-bugsnag	
# Version	: v0.0.0-20171204204709-577dee27f20d
# Source repo	: https://github.com/Shopify/logrus-bugsnag
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
# The Test are in parity with x86 for the requested and the top of the tree version:
# [root@5441a6ec5960 logrus-bugsnag@v0.0.0-20171204204709-577dee27f20d]# go test -v ./...
# github.com/shopify/logrus-bugsnag
# ./bugsnag_test.go:91:4: Error call has possible formatting directive %d
# FAIL    github.com/shopify/logrus-bugsnag [build failed]
# FAIL
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/shopify/logrus-bugsnag
PACKAGE_VERSION=${1:-v0.0.0-20171204204709-577dee27f20d}
PACKAGE_URL=https://github.com/Shopify/logrus-bugsnag

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
fi

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME*)

go mod init $PACKAGE_NAME
go mod tidy

# ----------------------------------------------------------------------------
# [root@5441a6ec5960 logrus-bugsnag@v0.0.0-20171204204709-577dee27f20d]# go test -v ./...
# github.com/shopify/logrus-bugsnag
# ./bugsnag_test.go:91:4: Error call has possible formatting directive %d
# FAIL    github.com/shopify/logrus-bugsnag [build failed]
# ----------------------------------------------------------------------------

if ! go test ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
