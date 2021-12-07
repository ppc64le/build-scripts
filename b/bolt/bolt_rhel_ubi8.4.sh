# -----------------------------------------------------------------------------
#
# Package       : bolt
# Version       : v1.3.1
# Source repo   : https://github.com/boltdb/bolt
# Tested on     : RHEL ubi 8.4
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

PACKAGE_PATH=github.com/boltdb/
PACKAGE_NAME=bolt
PACKAGE_VERSION=v1.3.1
PACKAGE_URL=https://github.com/boltdb/bolt

yum install -y wget make

# Install Go and setup working directory
wget https://golang.org/dl/go1.7.4.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.7.4.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg /home/tester/output

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export GOROOT=/bin/go/

mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#export GO111MODULE=on

if ! go get -d -t $PACKAGE_PATH$PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 0
fi

#/home/tester/go/src/github.com/boltdb/bolt
cd $(ls -d $GOPATH/src/$PACKAGE_PATH$PACKAGE_NAME)

echo `pwd`
echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go test -v -cover -timeout 3h ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
       	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
       	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
       	exit 0
fi

