# -----------------------------------------------------------------------------
#
# Package       : github.com/tinylib/msgp
# Version       : v1.1.3, v1.0.2
# Source repo   : https://github.com/tinylib/msgp
# Tested on     : RHEL 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vikas Gupta <vikas.gupta8@ibm.com>, Amit Mukati <amit.mukati3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
PACKAGE_NAME=msgp
PACKAGE_PATH=github.com/tinylib/msgp
PACKAGE_VERSION=${1:-v1.1.3}
PACKAGE_URL=https://github.com/tinylib/msgp

yum install -y git wget make

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

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@$PACKAGE_VERSION)

echo `pwd`

# Ensure go.mod file exists
go mod init github.com/tinylib/msgp
go mod tidy

# building with make
echo "Building and Testing $PACKAGE_PATH with $PACKAGE_VERSION"

chmod +x _generated/search.sh

if ! make all; then
        echo "------------------$PACKAGE_NAME: build failed-------------------------"
        exit 0
fi

if ! make test; then
        echo "------------------$PACKAGE_NAME: Test failed-------------------------"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi
