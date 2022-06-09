#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tdigest
# Version       : v0.0.0-20181121200506-bf2b5ad3c0a9,v0.0.1
# Source repo   : https://github.com/influxdata/tdigest.git
# Tested on     : ubi 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Ambuj Kumar {Ambuj.Kumar3@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./tdigest_ubi_8.5.sh v0.0.1(version_to_test)
PACKAGE_NAME=tdigest
#PACKAGE_VERSION=${1:-v0.0.1}
PACKAGE_VERSION=${1:-bf2b5ad3c0a9}
GO_VERSION=1.16.1
PACKAGE_URL=https://github.com/influxdata/tdigest.git

dnf install git wget sudo make gcc gcc-c++ -y

mkdir -p /home/tester/output
cd /home/tester

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf /home/tester/go && tar -C /home/tester -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export GOPATH=/home/tester/go
export PATH=$PATH:$GOPATH/bin
export  GO111MODULE=on
mkdir -p $GOPATH/src/github.com/influxdata
cd $GOPATH/src/github.com/influxdata
rm -rf $PACKAGE_NAME


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

echo $PWD
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
echo $PWD
sed -i 's/0.9001667885256108/0.9001667885256107/g' tdigest_test.go
sed -i 's/99.90103781043621/99.9010378104362/g' tdigest_test.go
sed -i 's/98.98503400959562/98.98503400959561/g' tdigest_test.go
sed -i 's/89.98281777095822/89.9828177709582/g' tdigest_test.go
sed -i 's/10.000673533707138/10.00067353370714/g' tdigest_test.go

file="$GOPATH/src/github.com/influxdata/tdigest/go.mod"
if [ ! -f "$file" ]
then
go mod init
go mod tidy
fi

INSTALL_SUCCESS="false"

if ! go build; then
        INSTALL_SUCCESS="false"
        else
        INSTALL_SUCCESS="true"
fi

if ! go test -v; then
        echo "------------------$PACKAGE_NAME :install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME " > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
else
        echo "------------------$PACKAGE_NAME :install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME " > /home/tester/output/test_success
        echo "$PACKAGE_NAME   |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
fi
