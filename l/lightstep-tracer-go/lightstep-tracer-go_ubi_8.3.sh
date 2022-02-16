
#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : lightstep-tracer-go
# Version       : v0.25.0
# Source repo   : https://github.com/lightstep/lightstep-tracer-go
# Tested on     : UBI 8.3
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
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/lightstep/lightstep-tracer-go
PACKAGE_VERSION=${1:-v0.25.0}
PACKAGE_URL=https://github.com/lightstep/lightstep-tracer-go

yum install -y git golang make

go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION

cd ~/go/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION
go mod tidy
go install
go test
