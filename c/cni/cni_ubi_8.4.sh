

#----------------------------------------------------------------------------
#
# Package               : cni 
# Version               : v0.7.1
# Source repo           : https://github.com/containernetworking/cni
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
  export VERSION=master
else
  export VERSION=$1
fi

if [ -d "cni" ] ; then
  rm -rf cni
fi

# Dependency installation
yum module install -y go-toolset
dnf install -y git

# Download the repos
git clone https://github.com/containernetworking/cni.git

# Build and Test gotest.tools
cd cni
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi


go get -v -t ./...
ret=$?
if [ $ret -ne 0 ] ; then
 echo "go get failed "
 exit
else
 go test -v ./...
fi
