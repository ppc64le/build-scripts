#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	     : godror/godror
# Version	     : v0.34.0
# Source repo    : https://github.com/godror/godror/
# Tested on	     : UBI 8.5
# Language       : GO
# Travis-Check   : TRUE
# Script License : Apache License, Version 2 or later
# Maintainer	 : Sonal Mahambrey <Sonal.Mahambrey1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/godror/godror/
PACKAGE_URL=https://github.com/godror/godror
PACKAGE_VERSION=${1:-v0.34.0}

GO_VERSION=go1.18.5

yum install -y git wget make gcc-c++ unzip


# install go
rm -rf /bin/go
wget https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  
rm -f $GO_VERSION.linux-ppc64le.tar.gz



# install Oracle instant client 19
rm -rf /opt/oracle
mkdir -p /opt/oracle
cd /opt/oracle
wget https://download.oracle.com/otn_software/linux/instantclient/193/instantclient-basic-linux.leppc64.c64-19.3.0.0.0dbru.zip
unzip instantclient-basic-linux.leppc64.c64-19.3.0.0.0dbru.zip
rm -f instantclient-basic-linux.leppc64.c64-19.3.0.0.0dbru.zip
export LD_LIBRARY_PATH=/opt/oracle/instantclient_19_3:$LD_LIBRARY_PATH
yum install -y libaio

#checking for libnsl.so.1 which is required for godror, however with client 19.3, libnsl.so.2 is installed
cd /usr/lib64/
if [ ! -f "libnsl.so.1" ]; then
echo "libnsl.so.1 does not exist. Creating symlink" 
ln -sf libnsl.so.2.0.0 libnsl.so.1
fi

# install godror package
cd /
mkdir -p `dirname $PACKAGE_NAME` && cd `dirname $PACKAGE_NAME`
git clone $PACKAGE_URL
cd `basename $PACKAGE_NAME`
git checkout $PACKAGE_VERSION 


sed -i -e '401 s/10/30/; 30 s/30/60/' queue_test.go
sed -i '3147 s/1/5/' z_test.go
sed -i '283i rec.rec.id := i;' z_plsql_types_test.go

# set go path
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi


if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Test_Fails"
	#Some test cases fail when run in batch so executing them individually
	go test -v  -run TestLOBAppend  ./...
	go test -v  -run TestFuncBool ./...
	go test -v  -run TestForError8192 ./...
	go test -v  -run TestHeterogeneousPoolIntegration ./...
	go test -v  -run TestOnInit  ./...
	go test -v  -run TestConnParamsTimezone ./...
	go test -v  -run TestHeterogeneousConnCreationWithProxy  ./...
	go test -v  -run TestWrongPassword  ./...
	go test -v  -run TestQueue  ./...
	go test -v  -run TestConcurrency  ./...
	go test -v  -run TestObjectTypeClose  ./...
	go test -v  -run TestSubObjectTypeClose  ./...
	go test -v  -run TestLoopInLoop_199  ./...
	#TestLOBAppend test behaviour in inconsistent and is in parity with intel wiht instant client version 19
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi

