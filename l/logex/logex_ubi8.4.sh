# ----------------------------------------------------------------------------
#
# Package        : logex
# Version        : v1.1.10
# Source repo    : https://github.com/chzyer/logex
# Tested on      : UBI 8.4
# Language       : GO
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
#!/bin/bash
set -e

PACKAGE_URL=https://github.com/chzyer/logex
PACKAGE_NAME=logex
PACKAGE_VERSION=v1.1.10

GO_VERSION=go1.17.5

yum install -y git wget tar make gcc-c++

#install go
rm -rf /bin/go
wget https://golang.org/dl/$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz
rm -f $GO_VERSION.linux-ppc64le.tar.gz

#set go path
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
mkdir -p /home/tester/go
cd $GOPATH

#clone package
mkdir -p $GOPATH/src/github.com/chzyer
cd $GOPATH/src/github.com/chzyer
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


go mod init
go mod tidy

go install ./...
#test cases failed. Same behviour observed on x86 platform as well
go test -v ./...

exit 0



