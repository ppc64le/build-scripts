# ----------------------------------------------------------------------------
#
# Package               : api
# Version               : 0.10.6,0.3.7 
# Source repo           : https://github.com/operator-framework/api
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
  export VERSION='v0.3.7'
else
  export VERSION=$1
fi

if [ -d "api" ] ; then
  rm -rf api
fi
# make sure to install make go under /root
# Dependency installation
cd
sudo dnf install -y git make wget tar gcc
sudo wget https://golang.org/dl/go1.16.7.linux-ppc64le.tar.gz
sudo tar -xvf go1.16.7.linux-ppc64le.tar.gz
export PATH=~/go/bin:$PATH

# Download the repos
git clone https://github.com/operator-framework/api

# Build and Test api
cd  api
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi
#verify build only for latest versions
if [ $VERSION ==  "v0.3.7" ] ; then
 make  install test-unit
else
 make  install verify test-unit
fi
ret=$?
if [ $ret -ne 0 ] ; then
   echo " build failed "
else
   go test -mod=vendor -v ./...
   ret=$?
   if [ $ret -ne 0 ] ; then
      echo " Test failed "
   else
      echo " Test Success "
   fi
fi
