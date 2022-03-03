#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : copy
# Version       : v1.7.0
# Source repo   : https://github.com/otiai10/copy
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

PACKAGE_NAME=copy
PACKAGE_VERSION=${1:-v1.7.0}
PACKAGE_URL=https://github.com/otiai10/copy

useradd -G root -d /home/tester tester -p test123

yum install git wget gcc sudo -y

GO_VERSION=1.16.2

wget https://go.dev/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

cd /home/tester/go/src
git clone --recurse $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

chown -R tester /home/tester

go get -v -t -d ./...

if ! go build -v .; then
    echo "------------------$PACKAGE_NAME:Build_Fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! sudo -E -u tester bash -c "/bin/go/bin/go test -v --tags=go1.16"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi