# ----------------------------------------------------------------------------
#
# Package	: gocql
# Version	: n/a
# Source repo	: https://github.com/gocql/gocql
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y wget
WDIR=`pwd`

wget https://storage.googleapis.com/golang/go1.9.1.linux-ppc64le.tar.gz
sudo tar -C /usr/ -zxvf go1.9.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/go/bin
export GOROOT=/usr/go
go version

# Create a directory structure to fetch and build gocql
mkdir -p gopath/src/github.com
export GOPATH="$WDIR/gopath"

# `hierarchy` variable hold folder structure used to build go code
hierarchy="$WDIR/gopath/src/github.com"

# Compile and test gocql
cd $hierarchy
go get github.com/gocql/gocql
cd gocql
go test -v ./...
