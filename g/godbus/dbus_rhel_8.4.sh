#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	 : godbus/dbus
# Version	 : v5.1.0
# Source repo	 : https://github.com/godbus/dbus
# Tested on	 : RHEL-8.4
# Language       : GO
# Travis-Check   : False
# Script License : Apache License, Version 2 or later
# Maintainer	 : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# This package has been tested on RHEL-8.4 as it has dependency on dbus & dbus-x11
# ----------------------------------------------------------------------------

PACKAGE_NAME=dbus
PACKAGE_URL=https://github.com/godbus/dbus
PACKAGE_VERSION=${1:-v5.1.0}

GO_VERSION=go1.17.5

yum install -y git wget make gcc-c++
yum install -y dbus dbus-x11

#install go
rm -rf /bin/go
wget https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  
rm -f $GO_VERSION.linux-ppc64le.tar.gz

#set go path
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
mkdir -p /home/tester/go
cd $GOPATH

#clone package
mkdir -p $GOPATH/src/github.com/godbus
cd $GOPATH/src/github.com/godbus
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi

<<test
 Below test case is failing on both Power & Intel that's because of SELinux by default enablement on RHEL.
 === RUN   TestTcpNonceConnection
 dbus-daemon[2075737]: [session uid=0 pid=2075737] Unable to set up new connection: Failed to read an SELinux context from connection
    transport_nonce_tcp_test.go:31: read tcp [::1]:56336->[::1]:43393: read: connection reset by peer
 --- FAIL: TestTcpNonceConnection (0.20s)

 Github CI is passing as they are building it on ubuntu, community issue has been raised for the same.
 On ubuntu vm all the test cases are passing.
 Link for community issue: https://github.com/godbus/dbus/issues/338
test

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi