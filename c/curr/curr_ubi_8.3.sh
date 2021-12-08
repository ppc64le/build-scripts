#----------------------------------------------------------------------------
#
# Package               : curr
# Version               : 1.0.0
# Source repo           : https://github.com/otiai10/curr
# Tested on             : UBI 8.3
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Script License        : Apache License, Version 2 or later
# Maintainer            : Arumugam N S<asellappen@yahoo.com>/Priya Seth<sethp@us.ibm.com>
#
# Disclaimer            : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

if [ -z "$1" ]; then
  export VERSION='v1.0.0'
else
  export VERSION=$1
fi

if [ -d "curr" ] ; then
  rm -rf curr
fi
#make sure to install under home path
cd
sudo dnf install -y git make wget tar gcc
sudo wget https://golang.org/dl/go1.16.7.linux-ppc64le.tar.gz
sudo tar -xvf go1.16.7.linux-ppc64le.tar.gz
export PATH=~/go/bin:$PATH
export GOPATH=~/go/bin
export GITHUB_WORKSPACE=~/curr

# Download the repos
git clone https://github.com/otiai10/curr

# Build and Test curr
cd  curr
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi

#test TestDir causing the issue due the code is referring the path which specified in file curr/all_test.go #for v1.0.0 and this is fixed in main now,hence trying to fix the same using sed for
#the ver v1.0.0 to complete all test cases

if [ $VERSION == "v1.0.0" ] ; then
  sed -i 's/gopath/\/\/gopath/g' all_test.go
  sed '15 i \\tpkgpath = os.Getenv("GITHUB_WORKSPACE")' all_test.go > mod_test.go
  sed -i '14d' mod_test.go
  mv mod_test.go all_test.go
fi

#build and test
go build -v ./...
ret=$?
if [ $ret -ne 0 ] ; then
   echo " Build failed "
   exit
fi
#Test
go test -v -cover -coverprofile=coverage.txt ./...
ret=$?
if [ $ret -ne 0 ] ; then
   echo " Test failed "
   exit
fi
echo " Build & Test Success.."
