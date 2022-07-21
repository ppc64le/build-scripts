#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: go-syslog
# Version	: v2.2.1
# Source repo	: https://github.com/mcuadros/go-syslog
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik / Vedang Wartikar<Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=go-syslog
PACKAGE_VERSION=${1:-v2.2.1}
PACKAGE_URL=https://github.com/mcuadros/go-syslog


yum install -y wget git make gcc gcc-c++

#Tests do not pass for latest go version. 
#Project requires v1.7 as stated in the travis.yml file.(https://github.com/mcuadros/go-syslog/blob/v2.2.1/.travis.yml)
wget https://go.dev/dl/go1.7.4.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.7.4.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/usr/local/go/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

rm -rf /usr/local/go/src/gopkg.in/mcuadros
mkdir -p /usr/local/go/src/gopkg.in/mcuadros
ln -s $PWD /usr/local/go/src/gopkg.in/mcuadros/go-syslog.v2

cd /usr/local/go/src/gopkg.in/mcuadros/go-syslog.v2 && go get -v -t ./...
cd /usr/local/go/src/gopkg.in/mcuadros/go-syslog.v2 && go test -v ./...