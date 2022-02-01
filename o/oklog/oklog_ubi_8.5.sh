#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : oklog
# Version       : v0.3.2
# Source repo   : https://github.com/oklog/oklog
# Tested on     : UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=oklog
PACKAGE_VERSION=${1:-v0.3.2}
PACKAGE_URL=https://github.com/oklog/oklog

yum install git gcc wget tar -y

GO_VERSION=1.17

# install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

# install dep
curl -LO https://raw.githubusercontent.com/golang/dep/master/install.sh
mkdir /home/tester/go/bin
chmod 700 install.sh
./install.sh
chmod +x $GOPATH/bin/dep
mv $GOPATH/bin/dep /usr/local/bin/

# running the go commands
cd /home/tester/go/src
git clone --recurse $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go get -d github.com/golang/dep/cmd/dep
dep ensure

go mod init
go mod tidy 

if ! go build -mod=readonly -v ./...; then
	echo "------------------$PACKAGE_NAME:Build_Fails-------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

go get github.com/prometheus/prometheus/pkg/rulefmt@master
go get github.com/pborman/uuid@v1.2.0

if ! go test -mod=readonly -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else		
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi