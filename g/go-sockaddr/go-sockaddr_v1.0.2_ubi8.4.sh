# -----------------------------------------------------------------------------
#
# Package	: go-sockaddr
# Version	: v1.0.2
# Source repo	: github.com/hashicorp/go-sockaddr
# Tested on	: UBI 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=go-sockaddr
PACKAGE_VERSION=${1:-v1.0.2}
PACKAGE_URL=github.com/hashicorp/go-sockaddr

yum install -y git wget gcc-c++ iproute

# Install Go and setup working directory
wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p output

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

echo "Building $PACKAGE_NAME with $PACKAGE_VERSION"
if ! go get -d -u -t $PACKAGE_URL@$PACKAGE_VERSION; then
	exit 0
fi

#/home/tester/go/pkg/mod/github.com/hashicorp/go-sockaddr@v1.0.2

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_URL@$PACKAGE_VERSION)
echo "Testing $PACKAGE_NAME with $PACKAGE_VERSION"

echo `pwd`

# Ensure go.mod file exists

if ! go test -v ./...; then
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi
