
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
PACKAGE_URL=github.com/lightstep/lightstep-tracer-go

yum install -y git golang make

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! go get -d -t $PACKAGE_URL@$PACKAGE_VERSION; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

cd ~/go/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION
if ! go mod tidy ; then
        echo "------------------$PACKAGE_NAME:initialize_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Initialize_Fails"
        exit 1
fi


if ! go test; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_and_Test_Success"
        exit 0
fi
