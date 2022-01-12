# ----------------------------------------------------------------------------
#
# Package       : archiver 
# Version       : v3.5.0
# Source repo   : https://github.com/mholt/archiver 
# Tested on     : UBI 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Ghumnar / Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
set -e

if [ -z "$1" ]; then
  export VERSION=v3.5.0
else
  export VERSION=$1
fi

if [ -d "archiver" ] ; then
  rm -rf archiver
fi

# Dependency installation
dnf install -y go git

mkdir -p /home/tester/go
export GOPATH=/home/tester/go

mkdir -p $GOPATH/src/github.com/mholt

cd $GOPATH/src/github.com/mholt/
# Download the repos
git clone https://github.com/mholt/archiver

cd archiver 
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi

#Build
go build cmd/arc/*.go
ret=$?

if [ $ret -eq 0 ] ; then
 echo "Build is successful"
else
 echo "Build command failed"
 exit
fi

#Test
echo "TESTING IN PROGRESS....."
go test -v
