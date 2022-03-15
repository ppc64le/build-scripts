# ----------------------------------------------------------------------------
#
# Package        : generic-admission-server
# Version        : v1.14.0
# Source repo    : https://github.com/openshift/generic-admission-server
# Tested on      : UBI 8.4
# Language       : go
# Script License : Apache License, Version 2 or later
# Maintainer     : Sandeep Yadav <sandeep.yadav10ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

PACKAGE_NAME=generic-admission-server
PACKAGE_PATH=https://github.com/openshift/generic-admission-server
VERSION="v1.14.0"
#GO_VERSION="go1.17.5"

#install dependencies
if [ -d "generic-admission-server" ] ; then
  rm -rf generic-admission-server
fi

# Dependency installation
dnf install -y git make golang

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/root/go/

# Download the repos
git clone https://github.com/openshift/generic-admission-server

# Build and Test generic-admission-server
cd  generic-admission-server
git checkout $VERSION

# Ensure go.mod file exists
go mod init github.com/openshift/generic-admission-server
go mod tidy
echo `pwd`

ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi
#to sync with the vendor directory 
go mod vendor
#verify build & test
make build
ret=$?
if [ $ret -ne 0 ] ; then
        echo " build failed "
else
        echo " Build Success "
fi
