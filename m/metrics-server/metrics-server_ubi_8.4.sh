# ----------------------------------------------------------------------------
#
# Package        : metrics-server
# Version        : 
# Source repo    : 
# Tested on      : UBI 8.4
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

PACKAGE_NAME=metrics-server
PACKAGE_VERSION="v0.3.2"
GO_VERSION="go1.10.1"

 
cd  /
#install dependencies
yum install -y wget git tar gcc-c++&& \

#install go
rm -rf /bin/go
wget https://golang.org/dl/$GO_VERSION.linux-ppc64le.tar.gz && \
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  && \
rm -f $GO_VERSION.linux-ppc64le.tar.gz && \

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go


mkdir -p $GOPATH/src/github.com/kubernetes-incubator
cd $GOPATH/src/github.com/kubernetes-incubator
git clone https://github.com/kubernetes-sigs/metrics-server.git && \
cd $PACKAGE_NAME
git checkout tags/$PACKAGE_VERSION

make all && \
go test ./pkg/... -v && \ 
exit 0
