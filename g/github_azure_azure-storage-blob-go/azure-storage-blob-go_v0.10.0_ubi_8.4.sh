# ----------------------------------------------------------------------------
#
# Package               : azure-storage-blob-go
# Version               : v0.10.0
# Source repo           : https://github.com/Azure/azure-storage-blob-go.git
# Tested on             : UBI 8.4
# Language              : GO
# Travis-Check          : True
# Script License        : Apache License, Version 2 or later
# Maintainer            : Nailusha Potnuru <pnailush@in.ibm.com>
#
# Disclaimer            : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -e

if [ -z "$1" ]; then
  export VERSION=${1:-v0.10.0}
else
  export VERSION=$1
fi
if [ -d "azure-storage-blob-go" ] ; then
  rm -rf azure-storage-blob-go
fi

# Dependency installation
dnf install -y git gcc

GO_VERSION=go1.16.5
rm -rf /usr/local/go
rm -rf /root/go

curl -O https://dl.google.com/go/${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xzf ${GO_VERSION}.linux-ppc64le.tar.gz

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
export GO111MODULE=on

# Download the repos

mkdir -p $GOPATH/github.com/Azure/
cd $GOPATH/github.com/Azure/
git clone https://github.com/Azure/azure-storage-blob-go.git
cd azure-storage-blob-go/
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi

# Build and Test
GOOS=linux go build ./azblob
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
go test -race -short -cover -v ./azblob
ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Successful "
  fi
fi

# Observed "runtime error: invalid memory address or nil pointer dereference" test failures for the version v0.10.0, which is in parity with Intel.
