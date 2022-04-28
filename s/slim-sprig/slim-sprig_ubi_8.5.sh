# -----------------------------------------------------------------------------
#
# Package       : slim-sprig
# Version       : 348f09dbbbc0(v0.0.0-20210107165309-348f09dbbbc0)
# Source repo   : https://github.com/go-task/slim-sprig.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------------

set -e
PACKAGE_NAME=github.com/go-task/slim-sprig
PACKAGE_VERSION=${1:-v0.0.0-20210107165309-348f09dbbbc0}
PACKAGE_URL=https://github.com/go-task/slim-sprig.git

export GOPATH=$HOME/go
mkdir $GOPATH
yum install -y golang

#Add dependency 
go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION
cd $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION/

#Build and test the package
go install ./...
go test ./...
