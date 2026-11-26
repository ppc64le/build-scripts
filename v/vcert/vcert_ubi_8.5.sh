#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : vcert
# Version       : v4.18.2
# Source repo   : https://github.com/Venafi/vcert.git
# Tested on     : UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ambuj Kumar <Abuj.Kumar3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

export PACKAGE_NAME=vcert
export PACKAGE_VERSION=${1:-v4.18.2}
export PACKAGE_URL=https://github.com/Venafi/vcert.git

dnf install -y git wget gcc make diffutils golang

export GOPATH=~/go
export PATH=$PATH:$GOPATH/bin
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.43.0

echo "Building $PACKAGE_NAME with $PACKAGE_VERSION"
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME: clone failed-------------------------"
    exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
make build
go mod tidy

if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME: build failed-------------------------"
    exit 1
fi

if ! make test; then
    echo "------------------$PACKAGE_NAME: test failed-------------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  build_&_test_both_success"
fi

# For TPP(Trust Protection Platform) test got authentication error 
#export TPP_URL=https://tpp.company.com/vedsdk/
#export TPP_USER=tpp-user
#export TPP_PASSWORD=tpp-password
#export TPP_ZONE='some\suggested_policy'
#export TPP_ZONE_RESTRICTED='some\locked_policy'
#export TPP_ZONE_ECDSA='some\ecdsa_policy'
# GOT This Error In TPP Test:::::
# panic: Post "https://tpp.venafi.example/vedauth/authorize/oauth": dial tcp: lookup tpp.venafi.example on 129.40.106.1:53: no such host

# For Cloud test got authentication error
#export CLOUD_URL=https://api.venafi.cloud/v1
#export CLOUD_APIKEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#export CLOUD_ZONE='My Application\Permissive CIT'
#export CLOUD_ZONE_RESTRICTED='Your Application\Restrictive CIT'
# GOT This Error In Cloud Test:::::
# vCert: 2022/08/07 15:33:42 Got 401 Unauthorized status for GET https://api.venafi.cloud/v1/v1/useraccounts
# connector_test.go:1679: vcert error: server error: unexpected status code on Venafi Cloud registration. Status: 401 Unauthorized
