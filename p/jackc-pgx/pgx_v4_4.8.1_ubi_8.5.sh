#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package        : github.com/jackc/pgx/v4
# Version        : v4.8.1,v4.0.0-20190420224344-cc3461e65d96
# Source repo    : https://github.com/jackc/pgx/v4
# Tested on      : UBI 8.4
# Language      : go
# Travis-Check  : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vaibhav Bhadade <vaibhav.bhadade@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=github.com/jackc/pgx/v4
PACKAGE_PATH=https://github.com/jackc/pgx/v4
PACKAGE_VERSION=${1:-v4.8.1}

#install dependencies
yum install -y  go git


#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/var/lib/pgsql/go/

if ! go get -d $PACKAGE_NAME@$PACKAGE_VERSION; then
                echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
                exit 0
fi
cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION)

# Ensure go.mod file exists
go mod init github.com/jackc/pgx/v4
go mod tidy
echo `pwd`

echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"

sudo -u postgres bash <<EOF
	#set GO PATH
	export PATH=$PATH:/bin/go/bin
	export GOPATH=/var/lib/pgsql/go/
		# create database for testing
		psql
		create database pgx_test;
		\c pgx_test;
		create domain uint64 as numeric(20,0);
		\q

	export PGX_TEST_DATABASE="host=/var/run/postgresql database=pgx_test"
	cd $GOPATH/pkg/mod/github.com/jackc/pgx/v4@$PACKAGE_VERSION/
	if ! go test -v ./... ; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME"
		echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
		exit 1
	else
		echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME"
		echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_and_Test_Success"
		exit 0
	fi
bash
EOF

exit 0
