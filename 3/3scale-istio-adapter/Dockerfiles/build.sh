# ----------------------------------------------------------------------------
# Package       : 3scale-istio-adapter 
# Version       : code-cleanups
# Source repo   : https://github.com/3scale/3scale-istio-adapter
# Tested on     : RHEL_8.2
# Script License: Apache License, Version 2 or later
# Maintainer    : Krishna Harsha Voora
#
# Disclaimer: This script has been tested in non-root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

#!/bin/bash

if [ -z $1 ] || [ "$1" == "laststablerelease" ]
then
	RELEASE_TAG=v2.0.0.1
else
	RELEASE_TAG=$1
fi

echo "RELEASE_TAG = $RELEASE_TAG"

# Download/Setup Golang 1.11
cd /usr/local/
wget https://golang.org/dl/go1.11.13.linux-ppc64le.tar.gz
tar -zxf go1.11.13.linux-ppc64le.tar.gz
rm -f go1.11.13.linux-ppc64le.tar.gz


# Update PATH Variables
export GOPATH=$HOME/ibm/
export PATH=$GOPATH/bin/:$PATH:/usr/local/go/bin/

# Repository Path
mkdir -p $GOPATH/bin/
mkdir -p $GOPATH/src/
mkdir -p $GOPATH/pkg/
mkdir -p $GOPATH/src/github.com/3scale/
cd $GOPATH/src/github.com/3scale/


# Install & Setup dep
curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

# Clone Repository
git clone https://github.com/3scale/3scale-istio-adapter -b $RELEASE_TAG
cd 3scale-istio-adapter

# Checkout v2.0.2 branch
# git checkout tags/v2.0.2

# Run dep
dep ensure -v

# Make
make build-adapter build-cli

# run tests if "runtest" only if passed as argument

if [ "$2" == "runtest" ]
then

	# Unit Tests
	make unit

	# Integration Tests
	make integration
fi

# Copy Binaries
cp _output/3scale-istio-adapter /ws/
cp _output/3scale-config-gen /ws/

# Clean Up
cd $HOME
rm -rf $GOPATH/
