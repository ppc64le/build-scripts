# ----------------------------------------------------------------------------
#
# Package       : try
# Version       : master,v1
# Source repo   : https://github.com/matryer/try
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

if [ -d "try" ] ; then
  rm -rf try
fi

# Dependency installation
sudo yum module install -y go-toolset
sudo dnf install -y git

# Download the repos
git clone https://github.com/matryer/try

# Build and Test try
cd try
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

# Apply the patch
git apply --ignore-whitespace ../try.patch
ret=$?
if [ $ret -eq 0 ] ; then
 echo "Successfully applied the patch"
else
 echo "Failed to apply the patch"
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
