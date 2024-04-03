# -----------------------------------------------------------------------------
#
# Package	: infinispan-operator
# Version	: 2.4.0.Final
# Source repo	: https://github.com/infinispan/infinispan-operator.git
# Tested on	: Red Hat Enterprise Linux 87(8.7) && 9 (9.3)
# Language      : Go
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Shubham Bhagwat(shubham.bhagwat@ibm.com)
#
# Disclaimer: This script has been tested in **root/non-root** mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# run as root user
# ----------------------------------------------------------------------------
#!/bin/bash


PACKAGE_NAME=infinispan-operator
PACKAGE_VERSION=2.4.0.Final
PACKAGE_URL=https://github.com/infinispan/infinispan-operator.git
PACKAGE_BRANCH=2.4.0.Final


GO_VERSION=1.21.8

#Install the required dependencies
yum install git gcc make wget tar zip -y

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

mkdir -p $GOPATH/src && cd $GOPATH/src

# Install operator-sdk
wget https://github.com/operator-framework/operator-sdk/releases/download/v1.24.1/operator-sdk_linux_ppc64le
chmod +x operator-sdk_linux_ppc64le
mv operator-sdk_linux_ppc64le /usr/local/bin/operator-sdk
operator-sdk version


#Clone the repository
git clone $PACKAGE_URL

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL -b $PACKAGE_BRANCH ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

# Increase timeout to resolve golangcli-lint timeout error
/home/go/src/infinispan-operator/bin/golangci-lint run --enable errorlint --timeout=10m
go mod vendor
make lint

if ! make test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else	
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
