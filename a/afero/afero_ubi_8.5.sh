#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : afero
# Version       : v1.2.2, v1.9.3, v1.6.0
# Source repo   : https://github.com/spf13/afero.git
# Tested on     : UBI-8.3, UBI-8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com, Vishaka Desai <Vishaka.Desai@ibm.com>, Shalmon Titre <Shalmon.Titre@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------------

PACKAGE_URL=https://github.com/spf13/afero
PACKAGE_NAME=afero
PACKAGE_VERSION=${1:-v1.9.3}

export GOPATH=$HOME/go
mkdir $GOPATH && mkdir $GOPATH/pkg 
yum install -y golang git

mkdir $GOPATH/pkg/mod && cd $GOPATH/pkg/mod 
git clone $PACKAGE_URL
cd $PACKAGE_NAME

#Build and test the package
if !(go install -v)
then
  echo "Failed to build the package"
  exit 1
fi

if !(go test -v)
then
  echo "Failed to validate the package"
  exit 2
fi
