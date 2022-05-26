#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : istio
# Version       : Commit(3b162effeb79918b421cb7094bc1c7f628534483)
# Source repo   : https://github.com/istio/istio.git
# Tested on     : UBI 8.4 
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
yum install -y make wget tar git gcc make
#
# Needs go version >=1.17
#
wget https://go.dev/dl/go1.17.5.linux-ppc64le.tar.gz
tar -C /usr/local -xvf go1.17.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm go1.17.5.linux-ppc64le.tar.gz
#
# Build istio and istio operator (istio operator moved under istio)
#
export BUILD_WITH_CONTAINER=0
PACKAGE_VERSION=${1:-3b162effeb79918b421cb7094bc1c7f628534483}
git clone https://github.com/istio/istio.git
cd istio 
git checkout $PACKAGE_VERSION
make
make test
