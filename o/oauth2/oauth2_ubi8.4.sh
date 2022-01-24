# -----------------------------------------------------------------------------
#
# Package       : oauth2
# Version       : v0.0.0-20211104180415-d3ed0bb246c8
# Source repo   : https://github.com/golang/oauth2
# Tested on     : UBI 8.4
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
PACKAGE_NAME=oauth2
PACKAGE_PATH=golang.org/x/oauth2
PACKAGE_VERSION=${1:-v0.0.0-20211104180415-d3ed0bb246c8}
PACKAGE_URL=https://github.com/golang/oauth2

yum install -y wget tar gcc-c++

wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

mkdir -p /home/tester/output

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"

if ! go get -d -u -t $PACKAGE_PATH; then
	echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
	exit 0
fi

#/home/tester/go/pkg/mod/golang.org/x/oauth2@v0.0.0-20211104180415-d3ed0bb246c8
cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@v0.0.0-20211104180415-d3ed0bb246c8)

echo `pwd`

# Ensure go.mod file exists
go mod init $PACKAGE_PATH

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
