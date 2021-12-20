# -----------------------------------------------------------------------------
#
# Package       : github.com/etcd-io/etcd and go.etcd.io/etcd
# Version       : v3.5.1
# Source repo   : https://github.com/etcd-io/etcd
# Tested on     : RHEL 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
PACKAGE_NAME=etcd
PACKAGE_PATH=github.com/etcd-io/etcd/v3
PACKAGE_VERSION=${1:-v3.5.1}
PACKAGE_URL=https://github.com/etcd-io/etcd

yum install -y git wget make gcc diffutils

wget https://golang.org/dl/go1.15.4.linux-ppc64le.tar.gz && tar -C /bin -xf go1.15.4.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

mkdir -p /home/tester/output

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on


echo "Building $PACKAGE_PATH with master branch"

if ! git clone --recurse $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
	exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! ./test.sh; then
	echo "------------------$PACKAGE_NAME: test.sh script failed -------------------------"
	echo "------------------$PACKAGE_NAME: trying with make test -------------------------"

	if ! make build; then
		echo "------------------$PACKAGE_NAME:build_ failed-------------------------"
		exit 0
	fi

	echo "make test from script"
	if ! make test; then
		echo "------------------$PACKAGE_NAME:test_ failed-------------------------"
		exit 0
	fi
fi 

echo "------------------$PACKAGE_NAME: success... -------------------------"
