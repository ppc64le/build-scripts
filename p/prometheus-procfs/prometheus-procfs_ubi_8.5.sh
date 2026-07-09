#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : prometheus/procfs
# Version       : v0.6.0
# Source repo   : https://github.com/microsoft/mimalloc.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# 
# ----------------------------------------------------------------------------

PACKAGE_NAME=procfs
PACKAGE_VERSION=${1:-v0.6.0}
PACKAGE_URL=https://github.com/prometheus/procfs.git

yum install -y git gcc-c++ make wget

#install GO1.17.7
cd /opt && wget https://golang.org/dl/go1.17.7.linux-ppc64le.tar.gz
tar -xzf go1.17.7.linux-ppc64le.tar.gz
rm -rf go1.17.7.linux-ppc64le.tar.gz
export GOPATH=`pwd`/gopath
export PATH=`pwd`/go/bin:$GOPATH/bin:$PATH

#Clone the Repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test the package.
make
make test
