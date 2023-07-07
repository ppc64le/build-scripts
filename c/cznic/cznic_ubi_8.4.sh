#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : cznic
# Version       : v0.0.0-20180608152220-f44710a21d00, 1.0.0
# Source repo   : https://github.com/cznic/internal.git
# Tested on     : UBI 8.4
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sachin K {sachin.kakatkar@ibm.com}, Reynold Vaz <Reynold.Vaz@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./cznic_ubi_8.4.sh 1.0.0
PACKAGE_NAME=internal
PACKAGE_VERSION=${1:-1.0.0}
PACKAGE_URL=https://github.com/cznic/internal

yum install go git -y

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

mkdir -p $GOPATH/src && cd $GOPATH/src
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init
go mod tidy

sed -i 's|github.com/cznic/internal/slice|github.com/cznic/common/slice|g' buffer/buffer.go
sed -i 's|github.com/cznic/internal/buffer|github.com/cznic/common/buffer|g' file/all_test.go
sed -i 's|github.com/cznic/internal/buffer|github.com/cznic/common/buffer|g' file/file.go

go get github.com/cznic/common/slice
go get github.com/cznic/common/buffer

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi

