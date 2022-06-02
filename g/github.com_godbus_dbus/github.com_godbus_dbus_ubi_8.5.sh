#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : dbus
# Version       : v5.0.4
# Source repo   : https://github.com/godbus/dbus
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vathsala . <vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=dbus
PACKAGE_VERSION=${1:-v5.0.4}
PACKAGE_URL=https://github.com/godbus/dbus

OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`

yum install -y wget git tar gcc

wget https://golang.org/dl/go1.17.linux-ppc64le.tar.gz
rm -rf /home/go && tar -C /home -xzf go1.17.linux-ppc64le.tar.gz
rm -f go1.17.linux-ppc64le.tar.gz
export GOPATH=/home/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export  GO111MODULE=on

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

#Test failing and is in parity with Intel
#conn_test.go:18: exec: "dbus-launch": executable file not found in $PATH
#--- FAIL: TestSessionBus (0.00s)
#panic: runtime error: invalid memory address or nil pointer dereference [recovered]
#panic: runtime error: invalid memory address or nil pointer dereference
#[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x1018c6a4]

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi
