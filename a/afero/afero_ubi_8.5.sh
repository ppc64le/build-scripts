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
PACKAGE_NAME=github.com/spf13/afero
PACKAGE_VERSION=${1:-v1.9.3}

export GOPATH=$ROOT/go
mkdir $GOPATH
yum install -y golang git

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME

#Build and test the package
go install -v
go test -v
