# ----------------------------------------------------------------------------
#
# Package               : universal-translator
# Version               : v0.18.0, v0.17.0
# Source repo           : https://github.com/go-playground/universal-translator.git
# Tested on             : UBI 8.4
# Language              : GO
# Travis-Check          : True
# Script License        : Apache License, Version 2 or later
# Maintainer            : Vikas . <kumar.vikas@in.ibm.com>, Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
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
  export VERSION=v0.17.0
else
  export VERSION=$1
fi
if [ -d "universal-translator" ] ; then
  rm -rf universal-translator
fi

# Dependency installation
dnf install -y git

if ! command -v go &> /dev/null
then
GO_VERSION=go1.16.12
rm -rf /usr/local/go
rm -rf /root/go

curl -O https://dl.google.com/go/${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xzf ${GO_VERSION}.linux-ppc64le.tar.gz

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
export GO111MODULE=auto
fi

# Download the repos
git clone https://github.com/go-playground/universal-translator.git

# Checkout version
cd universal-translator
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi

go get ./...
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
# Observed 1 test failure for the version v0.18.0 & v0.17.0, which is in parity with Intel.
# === RUN   TestBadExport
# testdata/readonly <nil> false
#     import_export_test.go:783: Expected 'open testdata/readonly/en.json: permission denied' Got '%!s(<nil>)'
# --- FAIL: TestBadExport (0.00s)
  go test -v ./...
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Successful "
  fi
fi
