# ----------------------------------------------------------------------------
#
# Package       : go-shellwords
# Version       : v1.0.12,v1.0.9
# Source repo   : https://github.com/mattn/go-shellwords
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

if [ -d "go-shellwords" ] ; then
  rm -rf go-shellwords
fi

# Dependency installation
sudo yum module install -y go-toolset
sudo dnf install -y git

# Download the repos
git clone https://github.com/mattn/go-shellwords

# Build and Test go-shellwords
cd go-shellwords
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
 ./go.test.sh
fi
