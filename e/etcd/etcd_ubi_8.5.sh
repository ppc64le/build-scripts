#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: etcd
# Version	: v3.5.1,v3.3.18,v0.0.0-20191023171146-3cf2f69b5738,v0.5.0-alpha.5.0.20200910180754-dd1b699fc489
# Source repo	: https://github.com/etcd-io/etcd
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

PACKAGE_NAME=etcd
PACKAGE_URL=https://github.com/etcd-io/etcd
PACKAGE_VERSION=${1:-v3.5.1}

yum install -y git make wget gcc

MINIMUM_VERSION_REQUIRE_GO_16="v3.5.1"

if [[ $PACKAGE_VERSION < $MINIMUM_VERSION_REQUIRE_GO_16 ]]
then
export GO_VERSION=1.12.9
else
export GO_VERSION=1.16.3
fi

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on


cd /home/tester/go/src
git clone --recurse $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! make build; then
	echo "------------------Build_fails---------------------"
	exit 1
else
	echo "------------------Build_success-------------------------"
	
fi


if ! make test; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	
fi

