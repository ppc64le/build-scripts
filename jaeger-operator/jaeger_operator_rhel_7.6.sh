# ----------------------------------------------------------------------------
#
# Package        : jaeger-operator
# Version        : v1.16.0
# Source repo    : https://github.com/jaegertracing/jaeger-operator
# Tested on      : RHEL 7.6
# Script License : Apache License, Version 2 or later
# Maintainer     : Rashmi Sakhalkar <srashmi@us.ibm.com>
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
BUILD_VERSION=v1.16.0

#Install libraries
yum update -y
yum install -y gcc
yum install -y openssl make wget git


#Install Go
wget https://dl.google.com/go/go1.13.6.linux-ppc64le.tar.gz -P /tmp
tar xf /tmp/go1.13.6.linux-ppc64le.tar.gz -C /usr/local/
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
rm -rf go1.13.6.linux-ppc64le.tar.gz

#Clone the source code & run the build
cd $WORKDIR
git clone https://github.com/jaegertracing/jaeger-operator
cd jaeger-operator && git checkout $BUILD_VERSION
GO_FLAGS="GOOS=linux GOARCH=ppc64le CGO_ENABLED=0 GO111MODULE=on" make install-tools
GO_FLAGS="GOOS=linux GOARCH=ppc64le CGO_ENABLED=0 GO111MODULE=on" make
