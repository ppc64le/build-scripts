#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : telegraf
# Version       : 1.27.4
# Source repo   : https://github.com/influxdata/telegraf
# Tested on     : UBI 8.7
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod.K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=telegraf
PACKAGE_VERSION=${1:-v1.27.4}
PACKAGE_URL=https://github.com/influxdata/telegraf.git
GO_VERSION=${GO_VERSION:-1.20.5}

WORKDIR=`pwd`

#Install the required dependencies
yum update -y
yum install -y make git wget tar gcc-c++

cd $WORKDIR
wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -zxvf go${GO_VERSION}.linux-ppc64le.tar.gz

export GOPATH=$WORKDIR/go
export PATH=$PATH:$GOPATH/bin

#Clone and build the source
mkdir -p ${GOPATH}/src/github.com/influxdata
cd ${GOPATH}/src/github.com/influxdata
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
make
make test
