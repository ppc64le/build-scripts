#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: go-zookeeper/zk
# Version	: v1.0.2
# Source repo	: https://github.com/go-zookeeper/zk.git
# Tested on	: UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=zk
PACKAGE_VERSION=${1:-v1.0.2}
PACKAGE_URL=https://github.com/go-zookeeper/zk.git

yum install -y golang git make gcc java-1.8.0-openjdk

cd /opt && git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init $PACKAGE_NAME
go mod tidy

make setup ZK_VERSION=3.4.12

go build ./...

go test -timeout 0 -race ./...
