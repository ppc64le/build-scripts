# ----------------------------------------------------------------------------
#
# Package       : archiver 
# Version       : v3.5.0, v3.2.0
# Source repo   : https://github.com/mholt/archiver 
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Nagesh Tarale <Nagesh.Tarale@ibm.com>
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

if [ -d "archiver" ] ; then
  rm -rf archiver
fi

# Dependency installation
sudo dnf update
sudo dnf install -y go git wget

# Download the repos
git clone https://github.com/mholt/archiver

cd archiver 
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
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
