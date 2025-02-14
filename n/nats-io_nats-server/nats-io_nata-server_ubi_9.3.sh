#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : nats-server
# Version          : v2.10.14
# Source repo      : https://github.com/nats-io/nats-server
# Tested on        : UBI: 9.3
# Language         : Go
# Travis-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=nats-server
PACKAGE_VERSION=${1:-v2.10.14}
PACKAGE_URL=https://github.com/nats-io/nats-server

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum -y update && yum install -y nodejs npm python3 python3-devel ncurses git jq wget gcc-c++

#install go1.20.14
wget https://go.dev/dl/go1.20.14.linux-ppc64le.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.20.14.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! go build ./... ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
if ! (go test -race -v -run=TestJetStreamCluster ./server -tags=skip_js_cluster_tests_2,skip_js_cluster_tests_3 -count=1 -vet=off -timeout=30m -failfast && go test -race -v -run=TestJetStreamCluster ./server -tags=skip_js_cluster_tests,skip_js_cluster_tests_2 -count=1 -vet=off -timeout=30m -failfast && go test -race -v -run=TestJetStreamSuperCluster ./server -count=1 -vet=off -timeout=30m -failfast && go test -race -v -run=TestMQTT ./server -count=1 -vet=off -timeout=30m -failfast) ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi