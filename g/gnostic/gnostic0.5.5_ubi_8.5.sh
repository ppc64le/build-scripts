#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: github.com/google/gnostic
# Version	: v0.5.5
# Source repo	: https://github.com/google/gnostic
# Tested on	: UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Eshant Gupta <eshant.gupta1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="github.com/google/gnostic"
PACKAGE_VERSION=${1:-v0.5.5}
PACKAGE_URL="https://github.com/google/gnostic"

yum install -y unzip wget go make

# Install Protobuf
wget https://github.com/protocolbuffers/protobuf/releases/download/v21.0/protoc-21.0-linux-ppcle_64.zip && unzip -o 'protoc-*' -d $HOME_DIR/protoc

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$PATH:/protoc/bin:/root/go/bin

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd ~/go/pkg/mod/$PACKAGE_NAME*
chmod +x COMPILE-PROTOS.sh
go get google.golang.org/protobuf

if ! make; then
	echo "------------------$PACKAGE_NAME:install_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

cd ~/go/pkg/mod/$PACKAGE_NAME*
if ! make test; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_Build_and_Test_Success"
	exit 0
fi
