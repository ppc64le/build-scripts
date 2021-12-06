# -----------------------------------------------------------------------------
#
# Package       : github.com/klauspost/readahead
# Version       : v1.3.1
# Source repo   : https://github.com/klauspost/readahead
# Tested on     : RHEL 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : BulkPackageSearch Automation <sethp@us.ibm.com> Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
PACKAGE_NAME=readahead
PACKAGE_PATH=github.com/klauspost/readahead
PACKAGE_VERSION=${1:-v1.3.1}
PACKAGE_URL=https://github.com/klauspost/readahead

yum -y update && yum install -y git wget 

wget https://golang.org/dl/go1.16.1.linux-ppc64le.tar.gz && tar -C /bin -xf go1.16.1.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

mkdir -p /home/tester/output

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

#if [ "$PACKAGE_VERSION" = "v1.2.0" ]; then
#	echo "VIKAS version is v1.2.0"
#	git clone --recurse https://github.com/vividcortex/ewma
#	git checkout $PACKAGE_VERSION
#	cd $PACKAGE_NAME
#else
#	echo "VIKAS version is v1.1.1"
#	if ! go get -d -u -t $PACKAGE_PATH@$PACKAGE_VERSION; then
#	        echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
#       	exit 0
#	fi
#	cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@$PACKAGE_VERSION)
#fi

echo `pwd`

echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"

# Ensure go.mod file exists
go mod init github.com/klauspost/readahead
go mod tidy

if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME:install__success but Test failed-------------------------"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi
