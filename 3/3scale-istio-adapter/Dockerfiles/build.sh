#!/bin/bash

# Install Pre-requisites 
yum repolist
yum install -y gcc make git curl wget



# Download/Setup Golang 1.11
cd /usr/local/
wget https://golang.org/dl/go1.11.13.linux-ppc64le.tar.gz
tar -zxf go1.11.13.linux-ppc64le.tar.gz
rm -f go1.11.13.linux-ppc64le.tar.gz


# Update PATH Variables
export GOPATH=/home/ibm/
export PATH=$GOPATH/bin/:$PATH:/usr/local/go/bin/

# Repository Path
mkdir -p $GOPATH/bin/
mkdir -p $GOPATH/src/
mkdir -p $GOPATH/pkg/
mkdir -p $GOPATH/src/github.com/3scale/
cd $GOPATH/src/github.com/3scale/


# Install & Setup dep
curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
git clone https://github.com/3scale/3scale-istio-adapter
cd 3scale-istio-adapter

# Checkout v2.0.2 branch
git checkout tags/v2.0.2

# Run dep
dep ensure -v

# Make
make build-adapter build-cli

# Unit Test
make unit

# Integration Test
make integration


########## Update/Copy Binaries ###########
# Based on https://github.com/3scale/3scale-istio-adapter/blob/master/Dockerfile
#######################
useradd -d /app/ app
cp _output/3scale-istio-adapter /app/
cp _output/3scale-config-gen /app/



####
# Clean-Up
####
rm -rf $GOPATH/
rm -rf /usr/local/go/
