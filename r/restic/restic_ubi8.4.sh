# ----------------------------------------------------------------------------
#
# Package       : restic
# Version       : v0.12.1
# Source repo   : https://github.com/restic/restic/
# Tested on     : rhel UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer's  : Santosh Magdum <santosh.magdum@us.ibm.com>
#                 Priya Seth <priya.seth@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

PACKAGE_NAME=vert.x
PACKAGE_PATH=github.com/restic/restic
PACKAGE_VERSION=${1:-v0.12.1}
PACKAGE_URL=https://github.com/restic/restic/

yum install -y git wget tar make python3 gcc-c++ fuse

ln -s /usr/bin/python3 /usr/bin/python

# --------- Installing ninja version v1.4.0 -----------------
echo "--------- Installing ninja version v1.4.0 -----------------"
git clone git://github.com/ninja-build/ninja.git
cd ninja
git checkout v1.4.0
./bootstrap.py
cp -r ./ninja /usr/bin/
ninja --version
cd ..

wget https://golang.org/dl/go1.16.4.linux-ppc64le.tar.gz && tar -C /bin -xf go1.16.4.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

mkdir -p /home/tester/output
export HOME_DIR=/home/tester

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"

if ! go get -d -u -t $PACKAGE_PATH@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
	exit 0
fi

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@$PACKAGE_VERSION)

echo `pwd`

go mod init $PACKAGE_PATH
go mod tidy

# building
echo "Building and Testing $PACKAGE_PATH with $PACKAGE_VERSION"

if ! go build -v ./...; then
        echo "------------------$PACKAGE_NAME: build and  Test failed-------------------------"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi

if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME: build and  Test failed-------------------------"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi

