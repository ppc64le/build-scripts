# ----------------------------------------------------------------------------
#
# Package               : Json-patch
# Version               : v0.0.0-20190203023257-5858425f7550
# Source repo           : https://github.com/evanphx/json-patch
# Language              : GO
# Travis-Check	        : True
# Tested on	        : UBI 8.5
# Script License        : Apache License, Version 2 or later
# Maintainer            : Vathsala . <vaths367@in.ibm.com>
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
  export VERSION=${1:-5858425f7550}
else
  export VERSION=$1
fi

if [ -d "json-patch" ] ; then
  rm -rf json-patch
fi

# Dependency installation
dnf install -y git gcc

if ! command -v go &> /dev/null
then
GO_VERSION=go1.16.12

curl -O https://dl.google.com/go/${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xzf ${GO_VERSION}.linux-ppc64le.tar.gz

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
export GO111MODULE=auto
fi

# Download the repos
git clone https://github.com/evanphx/json-patch


# Build and Test json-patch
cd json-patch
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi

#Build and test
go mod init patch.go
go mod tidy
go get -v -t ./...

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  go test -v ./...
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Successful "
  fi
fi

