# ---------------------------------------------------------------------
# 
# Package       : jaegertracing
# Version       : v1.30.0, v1.27.0
# Source repo 	: https://github.com/jaegertracing/jaeger.git
# Tested on     : UBI 8.3
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#  
# ---------------------------------------------------------------------

#!/bin/bash

set -e

PACKAGE_NAME=jaeger
PACKAGE_VERSION=${1:-v1.30.0}
PACKAGE_URL=https://github.com/jaegertracing/jaeger.git

export GOPATH=$HOME/go
mkdir $HOME/go

dnf install -y jq git golang
dnf module install -y nodejs:12

npm install -g yarn
yarn add caniuse-lite browserslist

mkdir -p $GOPATH/src/github.com/jaegertracing
cd $GOPATH/src/github.com/jaegertracing
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

git submodule update --init --recursive
yarn install
go get -d -u github.com/golang/dep
#Build and test the package.
go install
go test -v 
