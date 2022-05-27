#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : toml
# Version       : v0.4.1
# Source repo   : https://github.com/BurntSushi/toml
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prashant Khoje <prashant.khoje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=toml
PACKAGE_VERSION=v0.4.1
PACKAGE_URL=https://github.com/BurntSushi/toml.git

export GOPATH=$HOME/go
dnf install -y golang git

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export SRC=$GOPATH/src/github.com/toml
mkdir -p $SRC
cd $SRC
git clone $PACKAGE_URL
cd toml
git checkout $PACKAGE_VERSION

echo "Testing $PACKAGE_NAME with $PACKAGE_VERSION"
if ! go test -v ./...; then
        echo "------------------ $PACKAGE_NAME: test fail ---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME | $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Test fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "----------------- $PACKAGE_NAME: test success --------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME | $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass | Test success" > /home/tester/output/version_tracker
fi
