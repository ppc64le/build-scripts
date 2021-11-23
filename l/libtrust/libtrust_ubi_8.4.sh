# ----------------------------------------------------------------------------
#
# Package        : libtrust
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

# set -u
PACKAGE_NAME=libtrust
PACKAGE_VERSION="v0.0.0-20160708172513-aabc10ec26b7"

#echo $PACKAGE_VERSION
#IFS='-'
#read -ra PACKAGE_VERSION_SPLIT <<< $PACKAGE_VERSION
#PACKAGE_COMMIT_HASH=${PACKAGE_VERSION_SPLIT[2]}
 
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
#echo "$PACKAGE_URL" 
#git clone https://github.com/bifurcation/mint.git && \
wget https://proxy.golang.org/github.com/docker/libtrust/@v/$PACKAGE_VERSION.zip && \

echo "unzip package"
unzip $PACKAGE_VERSION &&\

echo "go to src"
cd github.com/docker/$PACKAGE_NAME@$PACKAGE_VERSION

echo "Install dependecies"
go get  ./... && \

echo "test package $PACKAGE_NAME@$PACKAGE_VERSION"
go test ./... -v && \

exit 0
