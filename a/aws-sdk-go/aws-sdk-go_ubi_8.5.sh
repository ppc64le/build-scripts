#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: aws-sdk-go
# Version	: v1.44.89
# Source repo	: https://github.com/aws/aws-sdk-go
# Tested on	: UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=aws-sdk-go
PACKAGE_VERSION=v1.44.84
PACKAGE_URL=https://github.com/aws/aws-sdk-go

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq wget gcc-c++ make

wget https://golang.org/dl/go1.16.1.linux-ppc64le.tar.gz
tar -C /bin -xf go1.16.1.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

export PATH=$PATH:/bin/go/bin
OS_NAME=`python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])"`
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! go build ./...; then
	echo "------------------Build_Install_fails---------------------"
	exit 1
else
	echo "------------------Build_Install_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi

make unit
go test ./...

if ! go test -tags codegen ./private/...; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION |"
fi
   
