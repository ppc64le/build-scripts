# ----------------------------------------------------------------------------
#
# Package       : promremotebench
# Version       : v0.8.0
# Source repo   : https://github.com/m3dbx/promremotebench.git
# Tested on     : UBI 8.2
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

cd $HOME

# Install dependencies
yum install -y make git tar wget gcc
wget https://golang.org/dl/go1.15.2.linux-ppc64le.tar.gz
tar -xzf go1.15.2.linux-ppc64le.tar.gz
rm -rf go1.15.2.linux-ppc64le.tar.gz
export PATH=`pwd`/go/bin:$PATH
export GOPATH=`pwd`/gopath

# Clone source and build
export PRB_HOME=$GOPATH/src/github.com/m3dbx
mkdir -p $PRB_HOME
cd $PRB_HOME
git clone https://github.com/m3dbx/promremotebench.git 
cd promremotebench
git checkout v0.8.0
cd src
go build ./cmd/promremotebench

