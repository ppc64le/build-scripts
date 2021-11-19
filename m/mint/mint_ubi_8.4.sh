# ----------------------------------------------------------------------------
#
# Package        : mint
# Version        : 
# Source repo    : https://github.com/bifurcation/mint
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
PACKAGE_NAME=mint
PACKAGE_VERSION="$v0.0.0-20180715133206-93c51c6ce115"

#echo $PACKAGE_VERSION
IFS='-'
read -ra PACKAGE_VERSION_SPLIT <<< $PACKAGE_VERSION
PACKAGE_COMMIT_HASH=${PACKAGE_VERSION_SPLIT[2]}
 
cd  /
#install dependencies
yum install -y wget git tar gcc-c++&& \

#install go
rm -rf /bin/go
wget https://golang.org/dl/go1.10.linux-ppc64le.tar.gz && \
tar -C /bin -xzf go1.10.linux-ppc64le.tar.gz  && \
rm -f go1.10.linux-ppc64le.tar.gz && \

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p $GOPATH/$PACKAGE_NAME/src
cd $GOPATH/$PACKAGE_NAME/src
echo "$PACKAGE_URL" 
git clone https://github.com/bifurcation/mint.git && \
cd $PACKAGE_NAME
git checkout $PACKAGE_COMMIT_HASH

#install dependencies
go get ./...


#start test
go test  ./... -v && \ 
	
exit 0
