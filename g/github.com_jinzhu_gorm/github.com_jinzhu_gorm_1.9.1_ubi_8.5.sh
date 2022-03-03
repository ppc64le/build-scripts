# ----------------------------------------------------------------------------
#
# Package        : github.com/jinzhu/gorm
# Version        : v1.9.1
# Source repo    : https://github.com/jinzhu/gorm
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

PACKAGE_NAME=github.com/jinzhu/gorm
PACKAGE_PATH=https://github.com/jinzhu/gorm
PACKAGE_VERSION=${1:-v1.9.1}

#install dependencies
yum install -y  go git

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/root/go/

if ! go get -d $PACKAGE_NAME@$PACKAGE_VERSION; then
                echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
                exit 0
fi
cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION)

# Ensure go.mod file exists
go mod init github.com/jinzhu/gorm
go mod tidy
echo `pwd`

echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"

cd $GOPATH/pkg/mod/github.com/jinzhu/gorm@$PACKAGE_VERSION/
if ! go test -v ./... ; then
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
