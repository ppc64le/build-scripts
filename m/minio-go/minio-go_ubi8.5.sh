# -----------------------------------------------------------------------------
#
# Package	: github.com/minio/minio-go/v6
# Version	: v6.0.49
# Source repo	: https://github.com/minio/minio-go
# Tested on	: ubi8.5
# Language	: GO
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
# Build is passing but the test is in parity.
# Error:
#pkg/s3signer/request-signature-v4_test.go:45:35: conversion from int to string yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
# --- FAIL: TestGetObjectCore (0.00s)
#     core_test.go:82: Error: Endpoint:  does not follow ip address or domain name standards.
# --- FAIL: TestGetObjectContentEncoding (0.00s)
#     core_test.go:275: Error: Endpoint:  does not follow ip address or domain name standards.
# --- FAIL: TestGetBucketPolicy (0.00s)
#     core_test.go:352: Error: Endpoint:  does not follow ip address or domain name standards.
# --- FAIL: TestCoreCopyObject (0.00s)
#     core_test.go:415: Error: Endpoint:  does not follow ip address or domain name standards.
# --- FAIL: TestCoreCopyObjectPart (0.00s)
# ----------------------------------------------------------------------------


PACKAGE_NAME=github.com/minio/minio-go/v6	
PACKAGE_VERSION=${1:-v6.0.49}
PACKAGE_URL=https://github.com/minio/minio-go

yum install -y wget git tar gcc

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

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


if ! go test ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
