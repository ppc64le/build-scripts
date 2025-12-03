# -----------------------------------------------------------------------------
#
# Package       : gojsonschema
# Version       : v1.2.0
# Source repo   : https://github.com/xeipuuv/gojsonschema.git
# Tested on     : UBI 8.3
# Language      : GO
# Ci-Check  : True
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
PACKAGE_NAME=github.com/xeipuuv/gojsonschema
PACKAGE_VERSION=${1:-v1.2.0}

export GOPATH=$HOME/go
mkdir $GOPATH
yum install -y golang

#Add dependency
go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION
cd $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION/

#build  and test the package
go install
go test -v
