# ----------------------------------------------------------------------------
#
# Package               : go-sysinfo 
# Version               : 1.7.0,1.1.1
# Source repo           : https://github.com/elastic/go-sysinfo
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
  export VERSION=master
else
  export VERSION=$1
fi

if [ -d "go-sysinfo" ] ; then
  rm -rf go-sysinfo
fi

# Dependency installation
sudo dnf install -y git golang 
# Download the repos
git clone https://github.com/elastic/go-sysinfo


# Build and Test go-sysinfo 
cd go-sysinfo 
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
  #windows test is not supported
  go test -v -run Test[^Host]
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Success "
  fi
fi
