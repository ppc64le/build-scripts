# -----------------------------------------------------------------------------
#
# Package	: github.com/prometheus/client_model
# Version	: v0.2.0
# Source repo	: https://github.com/prometheus/client_model
# Tested on	: UBI 8.5
# Language      : GO
# Script License: Apache License, Version 2 or later
# Maintainer	: Sandeep Yadav <Sandeep.Yadav10@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/prometheus/client_model
PACKAGE_VERSION=${1:-v0.2.0}

set -e

yum install -y git golang

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

#For protobuf version error
cd ~/go/pkg/mod/$PACKAGE_NAME*
go get github.com/golang/protobuf
go get github.com/golang/protobuf/proto@v1.5.2
go get github.com/golang/protobuf/ptypes/timestamp@v1.5.2

if ! go test ./...; then
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
