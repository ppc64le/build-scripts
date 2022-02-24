#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : fsnotify
# Version       : v1.5.1
# Source repo   : https://github.com/fsnotify/fsnotify.git
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

PACKAGE_NAME=github.com/fsnotify/fsnotify
PACKAGE_VERSION=${1:-v1.5.1}
PACKAGE_URL=https://github.com/fsnotify/fsnotify.git

yum install -y git golang

go get $PACKAGE_NAME@$PACKAGE_VERSION

cd ~/go/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION
go mod tidy
go install
go test ./...
