#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : gregjones/httpcache
# Version       : c63ab54fda8f77302f8d414e19933f2b6026a089,787624de3eb7bd915c329cba748687a3b22666a6
# Source repo   : https://github.com/gregjones/httpcache
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Maintainer    : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=httpcache
PACKAGE_VERSION=${1:-c63ab54fda8f77302f8d414e19933f2b6026a089}
PACKAGE_URL=https://github.com/gregjones/httpcache
yum install -y wget git gcc

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

cd /home/tester/go/src
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init
go mod tidy

if ! go build ./... ; then
	echo "------------------Build_fails---------------------"
	exit 1
else
	echo "------------------Build_success-------------------------"	
fi

if ! go test ./... -v ; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | Pass |  Install_and_Test_Success"	
fi