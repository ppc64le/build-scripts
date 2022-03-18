#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : istio
# Version       : maistra-2.2
# Source repo   : https://github.com/maistra/istio.git
# Tested on     : UBI 8.5 
# Script License: Apache License, Version 2 or later
# Maintainer    : Nishikant Thorat <Nishikant.Thorat@ibm.com>
# Travis-Check  : True
# Language	: go
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
# Install dependecies
#
yum install -y -q make wget tar git gcc make
#
# Needs go version >=1.17
#
wget -q https://go.dev/dl/go1.17.5.linux-ppc64le.tar.gz
tar -C /usr/local -xf go1.17.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm go1.17.5.linux-ppc64le.tar.gz
#
# Build istio and istio operator (istio operator moved under istio)
#
export BUILD_WITH_CONTAINER=0
PACKAGE_VERSION=${1:maistra-2.2}
git clone https://github.com/maistra/istio.git
cd istio 
git checkout $PACKAGE_VERSION
go mod vendor
GOFLAGS=-mod=vendor GOOS=linux GOARCH=ppc64le make
GOFLAGS=-mod=vendor GOOS=linux GOARCH=ppc64le make test
