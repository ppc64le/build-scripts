# ----------------------------------------------------------------------------
#
# Package               : gobuffalo/attrs
# Version               : v0.0.0-20190224210810-a9411de4debd
# Source repo           : https://github.com/gobuffalo/attrs.git
# Tested on             : UBI 8.4
# Language              : GO
# Travis-Check          : True
# Script License        : Apache License, Version 2 or later
# Maintainer            : Vikas . <kumar.vikas@in.ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -e

if [ -z "$1" ]; then
  export VERSION=a9411de4debd
else
  export VERSION=$1
fi
if [ -d "attrs" ] ; then
  rm -rf attrs
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
git clone https://github.com/gobuffalo/attrs.git

# Build and Test attrs
cd attrs
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi

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
