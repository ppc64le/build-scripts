# ----------------------------------------------------------------------------
#
# Package        : jaeger-operator
# Version        : v1.39.0
# Source repo    : https://github.com/jaegertracing/jaeger-operator
# Tested on      : RHEL 8.7 (Ootpa)
# Script License : Apache License, Version 2 or later
# Maintainer     : Shubham Bhagwat <shubham.bhagwat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

WORKDIR=`pwd`
BUILD_VERSION=v1.39.0

#Install libraries
echo "Install libraries..."
yum update -y
yum install -y gcc
yum install -y openssl make wget git


#Install Go
echo "Install GO..."
wget https://go.dev/dl/go1.18.linux-ppc64le.tar.gz -P /tmp
tar xf /tmp/go1.18.linux-ppc64le.tar.gz -C /usr/local/
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
rm -rf go1.18.linux-ppc64le.tar.gz

#Clone the source code & run the build
cd $WORKDIR
echo "Cloning..."
git clone https://github.com/jaegertracing/jaeger-operator
cd jaeger-operator && git checkout $BUILD_VERSION
echo "Building..."
GO_FLAGS="GOOS=linux GOARCH=ppc64le CGO_ENABLED=0 GO111MODULE=on" make install-tools
GO_FLAGS="GOOS=linux GOARCH=ppc64le CGO_ENABLED=0 GO111MODULE=on" make
echo "Script Complete!"

