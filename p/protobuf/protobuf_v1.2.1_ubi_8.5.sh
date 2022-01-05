# -----------------------------------------------------------------------------
#
# Package	: github.com/gogo/protobuf
# Version	: v1.2.1
# Source repo	: https://github.com/gogo/protobuf
# Tested on	: UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/gogo/protobuf
PACKAGE_VERSION=${1:-v1.2.1}
PACKAGE_URL=https://github.com/gogo/protobuf

yum install -y git golang make wget unzip

# Install Protobuf
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protoc-3.9.1-linux-ppcle_64.zip
unzip protoc-3.9.1-linux-ppcle_64.zip
cp -r include/* /usr/local/include
cp bin/protoc /usr/local/bin

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
HOME=`pwd`

export PATH=$PATH:~/go/bin

mkdir src && cd src

cd $HOME/src
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 1
fi

cd $HOME/src/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! make clean install regenerate; then
	echo "------------------$PACKAGE_NAME:install_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

# 1 Failing Test, in parity with Intel
# proto/text_parser.go:321:10: conversion from uint64 to string yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
# FAIL    github.com/gogo/protobuf/proto [build failed]
cd $HOME/src/$PACKAGE_NAME
if ! make tests errcheck; then
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
