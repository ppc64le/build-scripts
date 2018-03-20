# ----------------------------------------------------------------------------
#
# Package       : Redigo
# Version       : 1.6.0
# Source repo   : https://github.com/garyburd/redigo
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Dependencies
sudo apt-get update -y && sudo apt-get install -y golang-go git

# Set ENV variables
mkdir $HOME/gopath
export GOPATH=$HOME/gopath
export GOROOT=/usr/lib/go-1.6
export PATH=$PATH:/usr/bin:$GOPATH/bin

# Download source
cd $HOME
go get -u github.com/FiloSottile/gvt
cd $GOPATH/src/github.com/FiloSottile/gvt
gvt fetch github.com/garyburd/redigo

# Build and test
cd $GOPATH/src/github.com/FiloSottile/gvt/vendor
go build ./...
go test ./...
