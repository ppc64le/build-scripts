# ----------------------------------------------------------------------------
#
# Package               : go-fastjson
# Version               : v1.1.0, v1.0.0
# Source repo           : https://github.com/elastic/go-fastjson
# Tested on             : UBI 8.3
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Script License        : Apache License, Version 2 or later
# Maintainer            : RamaKrishna<ramakrishna.s@genisys-group.com>/Priya Seth<sethp@us.ibm.com>
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
  export VERSION=v1.0.0
else
  export VERSION=$1
fi

if [ -d "go-fastjson" ] ; then
  rm -rf go-fastjson
fi

# Dependency installation
sudo dnf install -y git golang 
# Download the repos
git clone https://github.com/elastic/go-fastjson


# Build and Test go-fastjson
cd go-fastjson
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
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
    echo "Build & unit tests Successful "
  fi
fi
