# ----------------------------------------------------------------------------
#
# Package       : sprig
# Version       : v3.1.0,v3.2.2
# Source repo   : https://github.com/masterminds/sprig
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Gururaj R Katti <Gururaj.Katti@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ -z "$1" ]; then
  export VERSION=master
else
  export VERSION=$1
fi

if [ -d "sprig" ] ; then
  rm -rf sprig
fi

# Dependency installation
sudo yum module install -y go-toolset
sudo dnf install -y git

# Download the repos
git clone https://github.com/masterminds/sprig

# Build and Test sprig
cd sprig
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
