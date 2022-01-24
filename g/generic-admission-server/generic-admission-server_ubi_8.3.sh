# ----------------------------------------------------------------------------
#
# Package               : generic-admission-server
# Version               : master
# Note                  : glide install required for v1.14.0 & previous versions
#                         and no glide support for UBI 
# Source repo           : https://github.com/openshift/generic-admission-server
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

if [ -d "generic-admission-server" ] ; then
  rm -rf generic-admission-server
fi

# Dependency installation
sudo dnf install -y git make golang
export GOPATH=/usr/bin
export GOBIN=$GOPATH/bin

# Download the repos
git clone https://github.com/openshift/generic-admission-server

# Build and Test generic-admission-server
cd  generic-admission-server
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi
#verify build & test  
make build
ret=$?
if [ $ret -ne 0 ] ; then
	echo " build failed "
else
    go test -v ./...
    ret=$?
    if [ $ret -ne 0 ] ; then
	  echo " Test failed "
    else
	  echo " Test Success "
    fi
fi
