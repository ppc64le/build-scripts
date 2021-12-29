# -----------------------------------------------------------------------------
#
# Package	: github.com/go-ini/ini
# Version	: v1.57.0
# Source repo	: https://github.com/go-ini/ini
# Tested on	: RHEL UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#PACKAGE_NAME=github.com/go-ini/ini
PACKAGE_NAME=gopkg.in/ini.v1
PACKAGE_VERSION=${1:-v1.57.0}
PACKAGE_URL=https://github.com/go-ini/ini

yum install -y git make wget gcc-c++

wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg /home/tester/output

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go


export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"
if ! go get -d -u -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_failed-------------------------"
	exit 0
fi

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION)

echo `pwd`

echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"
# Ensure go.mod file exists
go mod init github.com/go-ini/ini
go mod tidy

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:test_failed-------------------------"
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi
