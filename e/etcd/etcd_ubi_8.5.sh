# -----------------------------------------------------------------------------
#
# Package	: etcd
# Version	: v3.5.1, v3.5.0
# Source repo	: https://github.com/etcd-io/etcd
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

PACKAGE_NAME=etcd
PACKAGE_VERSION=${1:-v3.5.1}
PACKAGE_URL=https://github.com/etcd-io/etcd

yum install -y git golang make

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export GOPATH=$HOME/go
mkdir -p $GOPATH/src/github.com/etcd-io/

cd $GOPATH/src/github.com/etcd-io/
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Fail |  Clone_Fails"
	exit 0
fi

cd $GOPATH/src/github.com/etcd-io/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! make build; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

cd $GOPATH/src/github.com/etcd-io/$PACKAGE_NAME
if ! make test; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Build_and_Test_Success"
	
	# Copy binaries to GOPATH/bin
	cd $GOPATH/src/github.com/etcd-io/$PACKAGE_NAME
	cp -r bin/* $GOPATH/bin/
	echo "Copied binaries to $GOPATH/bin"
	exit 0
fi
