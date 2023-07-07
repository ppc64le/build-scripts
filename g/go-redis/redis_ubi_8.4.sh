# ----------------------------------------------------------------------------
#
# Package               : go-redis/redis
# Version               : v8.0.0-beta.5
# Source repo           : https://github.com/go-redis/redis.git
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
  export VERSION=v8.0.0-beta.5
else
  export VERSION=$1
fi
if [ -d "redis" ] ; then
  rm -rf redis
fi

# Dependency installation
yum install -y git make gcc wget

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
git clone https://github.com/go-redis/redis.git

# Checkout redis
cd redis
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi

mkdir -p testdata/redis
wget -qO- http://download.redis.io/redis-stable.tar.gz | tar xvz --strip-components=1 -C testdata/redis
cd testdata/redis
make all

cd ../..

go get ./...
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
# Observed 3 test failures for the version v8.0.0-beta.5, which are in parity with Intel. Details are provided in the README file.
