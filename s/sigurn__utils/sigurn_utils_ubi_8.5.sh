#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	 : github.com/sigurn/utils
# Version	 : f19e41f79f8f006116f682c1af454591bc278ad4
# Source repo	 : https://github.com/sigurn/utils
# Tested on	 : UBI 8.5
# Language       : GO
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer	 : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=utils
PACKAGE_URL=https://github.com/sigurn/utils
PACKAGE_VERSION=${1:-f19e41f79f8f006116f682c1af454591bc278ad4}

PACKAGE_COMMIT_HASH=`echo $PACKAGE_VERSION | cut -d'-' -f3`

GO_VERSION=go1.17.5

yum install -y git wget 

#install go
rm -rf /bin/go
wget https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  
rm -f $GO_VERSION.linux-ppc64le.tar.gz

#set go path
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
mkdir -p /home/tester/go
cd $GOPATH

#clone package
mkdir -p $GOPATH/src/github.com/sigurn
cd $GOPATH/src/github.com/sigurn
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_COMMIT_HASH

go mod init 
go mod tidy

go install ./...
go test -v ./...

exit 0