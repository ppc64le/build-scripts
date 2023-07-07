#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: mockery
# Version	: v0.0.0-20181123154057-e78b021dcbb5
# Source repo	: https://github.com/vektra/mockery
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=mockery
PACKAGE_URL=https://github.com/vektra/mockery
PACKAGE_VERSION=${1:-e78b021dcb}

yum install -y git golang

mkdir -p /home/tester/go/src 
export GOPATH=/home/tester/go

cd /home/tester/go/src
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! go install ./... ; then
	echo "------------------Build_fails---------------------"
	exit 1
else
	echo "------------------Build_success-------------------------"
	
fi

go get github.com/gostaticanalysis/nilerr/cmd/nilerr

if ! go test ./... ; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	
fi