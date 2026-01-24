# -----------------------------------------------------------------------------
#
# Package       : bbolt
# Version       : v1.3.3 v1.3.5
# Source repo   : https://github.com/etcd-io/bbolt
# Tested on     : RHEL ubi 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Vikas Gupta <vikas.gupta8@ibm.com>
# Language 	: GO
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_PATH=go.etcd.io/bbolt
PACKAGE_NAME=bbolt
PACKAGE_VERSION=${1:-v1.3.3}
PACKAGE_URL=https://github.com/etcd-io/bbolt

yum install -y wget make gcc gcc-c++ git


#https://github.com/etcd-io/bbolt/archive/refs/tags/v1.3.3.tar.gz

# Install Go and setup working directory
wget https://golang.org/dl/go1.12.4.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.12.4.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg /home/tester/output

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export GO111MODULE=on

mkdir -p output

if ! go get -d -u $PACKAGE_PATH@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 0
fi

#/home/tester/go/pkg/mod/github.com/etcd-io/bbolt@v1.3.3
cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@$PACKAGE_VERSION)

echo `pwd`

go mod init $PACKAGE_PATH
go mod tidy

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 0
fi

echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

# On ppc64le the go test is taking longer time more than 2h, hence running the test with --timeout 3h option.
if ! go test -v -cover -timeout 3h ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
       	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
       	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
       	exit 0
fi
