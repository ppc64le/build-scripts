# -----------------------------------------------------------------------------
#
# Package       : afero
# Version       : v1.2.2, v1.9.2
# Source repo   : https://github.com/spf13/afero.git
# Tested on     : UBI-8.3, UBI-8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com, Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------------

set -e
PACKAGE_NAME=github.com/spf13/afero
PACKAGE_VERSION=${1:-v1.9.2}

export GOPATH=$HOME/go
mkdir $GOPATH
yum install -y golang

#Add dependency 
go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION
cd $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION/

#Build and test the package
go install
go test -v
