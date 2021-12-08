#----------------------------------------------------------------------------
#
# Package               : gziphandler 
# Version               : 1.1.1,1.1.0
# Source repo           : https://github.com/nytimes/gziphandler
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

if [ -d "gziphandler" ] ; then
  rm -rf gziphandler
fi

# Dependency installation
sudo dnf install -y git golang 
# Download the repos
git clone https://github.com/nytimes/gziphandler


# Build and Test gziphandler
cd gziphandler 
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION  not found "
 exit
fi

#Build and test
go get -v -t ./...
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  go test -v ./...
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & Tests Success "
  fi
fi

