# ----------------------------------------------------------------------------
#
# Package       : grpc-gateway 
# Version       : v2.6.0
# Source repo   : https://github.com/grpc-ecosystem/grpc-gateway  
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
  export VERSION="v2.6.0"
else
  export VERSION=$1
fi

if [ -d "grpc-gateway" ] ; then
  rm -rf grpc-gateway
fi

# Dependency installation
dnf update
dnf install -y go git wget

# Download the repos
git clone https://github.com/grpc-ecosystem/grpc-gateway 

cd grpc-gateway
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout......... "
else
 echo "$Version not found.............. "
 exit
fi

#Build
go mod tidy
ret=$?

if [ $ret -eq 0 ] ; then
 echo "Build command is successful"
else
 echo "Build command failed"
 exit
fi

go build ./...
ret=$?

if [ $ret -eq 0 ] ; then
 echo "Build successful"
else
 echo "Build failed"
 exit
fi


#Test
echo "TESTING IN PROGRESS....."
go test -v ./...
