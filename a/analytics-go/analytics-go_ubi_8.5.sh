#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : segmentio/analytics-go
# Version       : v2.0.1-0.20160426181448-2d840d861c32+incompatible
# Source repo   : https://github.com/segmentio/analytics-go.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    :  Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# 
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/segmentio/analytics-go
PACKAGE_VERSION=${1:-v2.0.1-0.20160426181448-2d840d861c32+incompatible}
PACKAGE_URL=https://github.com/segmentio/analytics-go.git

yum install -y gcc-c++ make wget

#install GO1.13
cd /opt && wget https://golang.org/dl/go1.13.linux-ppc64le.tar.gz && tar -C /bin -xf go1.13.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg
rm -rf go1.13.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

#Clone the Repo.
go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION
cd $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION

#Build and test the package.
go mod init analytics-go
go mod tidy
go install
go test
