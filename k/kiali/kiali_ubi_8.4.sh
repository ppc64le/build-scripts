#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : kiali
# Version       : f72ddd308c155aa00bd492a423b5aebc88b5922f
# Source repo   : https://github.com/kiali/kiali/
# Tested on     : UBI 8.4
# Language      : go
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Nishikant Thorat <Nishikant.Thorat@ibm.com>
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
set -ex

yum update -y
yum install -y gcc
yum install -y make
yum install -y wget git

PACKAGE_VERSION=${1:-f72ddd308c155aa00bd492a423b5aebc88b5922f}

#Installing go
wget -c https://golang.org/dl/go1.17.5.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.5.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

mkdir kiali_sources
cd kiali_sources
export KIALI_SOURCES=$(realpath .)

#Cloning into local machine
git clone https://github.com/kiali/kiali.git
#Build kiali
cd $KIALI_SOURCES/kiali
#Checking out to mentioned/working version
git checkout $PACKAGE_VERSION
make build test
#For running tests
go test -v ./...
