#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : nomad
# Version          : v1.4.3
# Source repo      : https://github.com/hashicorp/nomad
# Tested on        : UBI 8.5
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------
# Variables
set -e
PACKAGE_NAME=nomad
PACKAGE_URL=https://github.com/hashicorp/nomad
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-1.4.3}
GO_VERSION=${GO_VERSION:-1.20.1}


#Dependencies
dnf install -y git wget make gcc gcc-c++
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go 
tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
go version

go install gotest.tools/gotestsum@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.50.1

#building consul 
git clone https://github.com/hashicorp/consul
cd consul
make dev-build
consul version
cd ..

#building vault
git clone https://github.com/hashicorp/vault
cd vault
go mod tidy
go mod vendor
make bootstrap
make dev
vault version
cd ..

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
fi

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! go build -v ./... ; then
    echo "------------------$PACKAGE_NAME:build_fail---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

# As Nomad testing requires clusters. Currently not supporting it.
# We need to work on cluster testing (probably using minikube or something) and enable tests.
# go test -v ./...



 
