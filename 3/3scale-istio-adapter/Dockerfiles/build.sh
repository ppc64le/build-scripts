#!/bin/bash

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
git clone https://github.com/3scale/3scale-istio-adapter -b code-cleanups
cd 3scale-istio-adapter

# Checkout v2.0.2 branch
# git checkout tags/v2.0.2

# Run dep
dep ensure -v

# Make
make build-adapter build-cli

# Unit Test
make unit

# Integration Test
make integration

# Copy Binaries
cp _output/3scale-istio-adapter /ws/
cp _output/3scale-config-gen /ws/
