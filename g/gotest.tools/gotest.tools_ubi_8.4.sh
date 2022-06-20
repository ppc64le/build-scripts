#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : gotest.tools
# Version       : v3.0.2, v3.0.3
# Source repo   : https://github.com/gotestyourself/gotest.tools
# Tested on     : UBI 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Gururaj R Katti <Gururaj.Katti@ibm.com>, Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

if [ -z "$1" ]; then
  export VERSION=master
else
  export VERSION=$1
fi

if [ -d "gotest.tools" ] ; then
  rm -rf gotest.tools
fi

# Dependency installation
sudo yum module install -y go-toolset
sudo dnf install -y git

# Download the repos
git clone https://github.com/gotestyourself/gotest.tools

# Build and Test gotest.tools
cd gotest.tools
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

export GO111MODULE="auto"
go get -v -t ./...
ret=$?
if [ $ret -ne 0 ] ; then
 echo "go get failed "
 exit
else
 go test -v ./...
fi
