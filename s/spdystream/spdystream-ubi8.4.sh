#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package        : spdystream
# Version        : v0.0.0-20181023171402-6480d4af844c
# Source repo    : https://github.com/moby/spdystream
# Tested on      : UBI 8.4
# Language       : GO
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Sapana Khemkar <spana.khemkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=spdystream
PACKAGE_VERSION="v0.0.0-20181023171402-6480d4af844c"
PACKAGE_URL="https://github.com/moby/spdystream.git"
PACKAGE_COMMIT_HASH=`echo $PACKAGE_VERSION | cut -d'-' -f3` 

GO_VERSION="1.17.3"

cd  /
#install dependencies
yum install -y wget git tar gcc-c++

#install go
rm -rf /bin/go
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz  
tar -C /bin -xzf go$GO_VERSION.linux-ppc64le.tar.gz  
rm -f go$GO_VERSION.linux-ppc64le.tar.gz 

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p $GOPATH/src/github.com/moby
cd $GOPATH/src/github.com/moby

git clone https://github.com/moby/spdystream.git
cd $PACKAGE_NAME
git checkout $PACKAGE_COMMIT_HASH

#install dependencies
go mod init 
#go mod tidy

go get ./...
go build ./...
#start test
go test  ./... -v  
	

exit 0
