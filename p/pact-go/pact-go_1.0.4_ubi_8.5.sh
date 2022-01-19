# ----------------------------------------------------------------------------
#
# Package        : pact-go
# Version        : v1.0.4
# Source repo    : https://github.com/pact-foundation/pact-go
# Tested on      : UBI 8.4
# Language      : go
# Travis-Check  : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vaibhav Bhadade <vaibhav.bhadade@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash -e

PACKAGE_NAME=pact-go
PACKAGE_PATH=github.com/pact-foundation/pact-go
PACKAGE_VERSION=${1:-v1.0.4}
GO_VERSION="go1.17.5"

#install dependencies
yum install -y  go git ruby ruby-devel make redhat-rpm-config
gem install pact-mock_service pact-provider-verifier pact_broker-client


#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/root/go/

if ! go get -d $PACKAGE_PATH@$PACKAGE_VERSION; then
                echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
                exit 0
fi
cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@$PACKAGE_VERSION)

# Ensure go.mod file exists
go mod init github.com/pact-foundation/pact-go
go mod tidy
echo `pwd`

echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"

cd $GOPATH/pkg/mod/github.com/pact-foundation/pact-go@$PACKAGE_VERSION/examples/
if ! go test -v -run TestConsumer ; then
echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_and_Test_Success"
        exit 0
fi
