#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package        : github.com/coreos/go-systemd
# Version        : 48702e0da86bd25e76cfef347e2adeb434a0d0a6
# Source repo    : https://github.com/coreos/go-systemd
# Tested on      : UBI 8.4
# Language      : go
# Travis-Check  : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vaibhav Bhadade <vaibhav.bhadade@ibm.com>
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
PACKAGE_VERSION=${1:-48702e0da86bd25e76cfef347e2adeb434a0d0a6}
GO_VERSION="go1.17.5"

 
#install dependencies
yum install -y wget git tar dbus gcc-c++ systemd-devel\

#install go
rm -rf /bin/go
rm -rf /home/tester/go/
wget https://golang.org/dl/$GO_VERSION.linux-ppc64le.tar.gz && \
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  && \
rm -f $GO_VERSION.linux-ppc64le.tar.gz && \

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p $GOPATH/src/github.com/coreos
cd $GOPATH/src/github.com/coreos

git clone https://github.com/coreos/go-systemd && \
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init
go mod tidy
go test ./... -v && \
exit 0




