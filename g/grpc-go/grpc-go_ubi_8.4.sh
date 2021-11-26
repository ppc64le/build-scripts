# ----------------------------------------------------------------------------
#
# Package       : grpc-go 
# Version       : v1.16.0, v1.41.0
# Source repo   : https://github.com/grpc/grpc-go 
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

if [ -d "grpc-go" ] ; then
  rm -rf grpc-go
fi

# Dependency installation
sudo dnf update
sudo dnf install -y go git wget

# Download the repos
git clone https://github.com/grpc/grpc-go

cd grpc-go 
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

#Installation
go get -u /grpc-go 

ret=$?

if [ $ret -eq 0 ] ; then
 echo "The grpc-go install is successful"
else
 echo "Failed to install grpc-go"
 exit
fi

#Build
go mod tidy
ret=$?

if [ $ret -eq 0 ] ; then
 echo "go mod tidy build command is successful"
else
 echo "1.Build command failed"
 exit
fi

go mod vendor
ret=$?

if [ $ret -eq 0 ] ; then
 echo "go mod vendor build command is successful"
else
 echo "2.Build command failed"
 exit
fi

go build -mod=vendor
ret=$?

if [ $ret -eq 0 ] ; then
 echo "go mod -mod=vendor build command is successful"
else
 echo "3.Build command failed"
 exit
fi

#Test
echo "TESTING IN PROGRESS....."
go test -v
