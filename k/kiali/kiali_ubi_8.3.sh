# ----------------------------------------------------------------------------
#
# Package       : kiali
# Version       : v1.35.0
# Source repo   : https://github.com/kiali/kiali/
# Tested on     : ubi: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Docker must be installed
#!/bin/bash

yum update -y
yum install -y gcc
yum install -y make
yum install -y wget git

BUILD_VERSION=v1.35.0

#Installing go
wget -c https://golang.org/dl/go1.16.2.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.16.2.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

mkdir kiali_sources
cd kiali_sources
#Checking out to latest version
git checkout $BUILD_VERSION
export KIALI_SOURCES=$(realpath .)

#Cloning into local machine
git clone https://github.com/kiali/kiali.git

#Build kiali
cd $KIALI_SOURCES/kiali
make build test
#For running tests
go test -v ./...