# -----------------------------------------------------------------------------
#
# Package	: beorn7/perks
# Version	: 1.0.1
# Source repo	: https://github.com/beorn7/perks
# Tested on	: ubi 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla<Sapna.Shukla@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=perks
PACKAGE_VERSION=${1:-v1.0.1}
PACKAGE_URL=https://github.com/beorn7/perks

yum install -y wget git tar 

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

#running the go commands
cd /home/tester/go/src
git clone --recurse $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! go install -v ./...; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  intsall_Fails"
	exit 1
fi


if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:test_fails-------------------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	echo "------------------$PACKAGE_NAME:Installed at path: /home/tester/go/src/$PACKAGE_NAME------------------------"
	exit 0
fi

