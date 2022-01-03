# -----------------------------------------------------------------------------
#
# Package       : github.com/bits-and-blooms/bloom and github.com/willf/bloom are same
# Version       : v2.0.3
# Source repo   : https://github.com/bits-and-blooms/bloom
# Tested on     : RHEL 8.4
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
#
PACKAGE_NAME=bloom
PACKAGE_PATH=github.com/bits-and-blooms/bloom
PACKAGE_VERSION=${1:-v2.0.3}
PACKAGE_URL=https://github.com/bits-and-blooms/bloom

yum install -y wget tar

wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

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

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@$PACKAGE_VERSION+incompatible/)

echo `pwd`

# Ensure go.mod file exists
go mod init $PACKAGE_PATH

go get ./...

go mod tidy

# building
echo "Building and Testing $PACKAGE_PATH with $PACKAGE_VERSION"

if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME: build and  Test failed-------------------------"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi
