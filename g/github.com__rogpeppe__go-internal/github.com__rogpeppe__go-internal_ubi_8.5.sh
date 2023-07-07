#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : go-internal
# Version       : v1.5.0, v1.6.1
# Source repo   : https://github.com/rogpeppe/go-internal
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vathasala . <vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=go-internal
PACKAGE_VERSION=${1:-v1.5.0}
PACKAGE_URL=https://github.com/rogpeppe/go-internal

OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`


yum install -y  make gcc git wget

wget https://golang.org/dl/go1.12.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.12.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go build -a -v ./...

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  go test -a -v ./...
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Successful "
  fi
fi

