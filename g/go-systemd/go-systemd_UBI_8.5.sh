#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package        : github.com/coreos/go-systemd
# Version        : v22.3.2
# Source repo    : https://github.com/coreos/go-systemd
# Tested on      : UBI 8.5
# Language       : go
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Shalmon Titre <Shalmon.Titre1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=go-systemd
PACKAGE_VERSION=${1:-v22.3.2}
GO_VERSION="go1.17.5"

#install dependencies
yum install -y wget git tar dbus gcc-c++ systemd-devel libffi-devel go 

git clone https://github.com/coreos/go-systemd && \
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd ..
mv dlopen_example.go go-systemd/internal/dlopen/
cd $PACKAGE_NAME

sed -i '9d' scripts/ci-runner.sh

sed -i '9 i PACKAGES="activation daemon dbus internal/dlopen journal login1 machine1 sdjournal unit util import1"' scripts/ci-runner.sh
go mod tidy
go test ./... -v && \
exit 0

#Build Script when running on Host has failures in dbus,import1,machine1
#Build Script when running inside container has failures in dbus,import1,journal,login1,machine1,sdjournal

