# ----------------------------------------------------------------------------
#
# Package		: kit
# Version		: v0.12.0,v0.10.0
# Source repo	: https://github.com/go-kit/kit
# Tested on		: UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Nageswara Rao K<nagesh4193@gmail.com>/Priya Seth<sethp@us.ibm.com>
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

if [ -d "kit" ] ; then
  rm -rf kit 
fi

# Dependency installation
sudo dnf install -y git golang 
# Download the repos
git clone  https://github.com/go-kit/kit


# Build and Test kit 
cd kit 
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

#Build and test
go get -v -t ./...

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  go test -v ./...
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Success "
  fi
fi
