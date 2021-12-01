# ----------------------------------------------------------------------------
#
# Package        : libtrust
# Version        : v0.0.0-20160708172513-aabc10ec26b7
# Source repo    : https://github.com/docker/libtrust.git
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

# set -u
PACKAGE_NAME=libtrust
PACKAGE_VERSION="v0.0.0-20160708172513-aabc10ec26b7"

PACKAGE_COMMIT_HASH=`echo $PACKAGE_VERSION | cut -d'-' -f3` 
cd  /
#install dependencies
yum install -y wget git tar unzip gcc-c++&& \

#install go
rm -rf /bin/go
wget https://golang.org/dl/go1.10.linux-ppc64le.tar.gz && \
tar -C /bin -xzf go1.10.linux-ppc64le.tar.gz  && \
rm -f go1.10.linux-ppc64le.tar.gz && \

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p $GOPATH/src
cd $GOPATH/src
git clone https://github.com/docker/libtrust.git && \
cd $PACKAGE_NAME
git checkout $PACKAGE_COMMIT_HASH

echo "Install dependecies"
go get  ./... && \

echo "test package $PACKAGE_NAME@$PACKAGE_VERSION"
go test ./... -v && \

exit 0
