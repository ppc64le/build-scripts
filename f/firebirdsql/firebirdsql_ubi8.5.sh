#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: firebiedsql
# Version	: v0.0.0-20190310045651-3c02a58cfed8
# Source repo	: https://github.com/helm/helm-2to3
# Tested on	: ubi 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer	: Amit Mukati <amit.mukati3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#note:- Before running the script first create a file a.sql ans past the below content which create database and user.
#        CREATE DATABASE 'FB';
#        CONNECT 'FB';
#        CREATE USER SYSDBA PASSWORD 'masterkey';
#        commit;
#        exit;
# ----------------------------------------------------------------------------

PACKAGE_NAME="nagakami/firebiedsql"
PACKAGE_VERSION=${1:-"3c02a58cfed8"}
PACKAGE_URL="https://github.com/nakagami/firebirdsql"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

export GO_VERSION=${GO_VERSION:-"1.17.4"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $3 "/" $4;}' <<<"$PACKAGE_URL" | xargs printf "%s" "$GOPATH")
export PACKAGE_SOURCE_ROOT

echo "installing dependencies from system repo"
dnf install -y wget git gcc-c++ make libicu >/dev/null

# installing golang
wget https://golang.org/dl/go"$GO_VERSION".linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz
export GO111MODULE=on

#installing firebird
dnf -qy install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum -y install epel-release
yum -y install firebird

if ! git clone "$PACKAGE_URL" "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"
cp attic/firebird.conf /etc/firebird
git checkout "$PACKAGE_VERSION" || exit 1

firebird &
isql-fb -q -i /a.sql


export ISC_USER="SYSDBA"
export ISC_PASSWORD="masterkey"

if [ -f "go.mod" ];
then
	rm go.mod go.sum
fi
	go mod init $PACKAGE_NAME
	go mod tidy
if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi