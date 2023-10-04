#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : filebeat
# Version       : 8.5.0
# Source repo   : https://github.com/elastic/beats.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=filebeat

PACKAGE_VERSION=${1:-v8.5.0}
PACKAGE_URL=https://github.com/elastic/beats.git
GO_VERSION=${GO_VERSION:-1.20.6}


WORKDIR=`pwd`

#Install the required dependencies
yum update -y
yum install -y wget git make gcc-c++ python3-virtualenv

cd $WORKDIR
wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -zxvf go${GO_VERSION}.linux-ppc64le.tar.gz


export GOPATH=$WORKDIR/go
export PATH=$PATH:$GOPATH/bin
export CGO_ENABLED="0"

#Clone and build the source
mkdir -p ${GOPATH}/src/github.com/elastic
cd ${GOPATH}/src/github.com/elastic
git clone $PACKAGE_URL
cd beats
git checkout $BEATS_VERSION
cd $PACKAGE_NAME
make
make unit

