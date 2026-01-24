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
PACKAGE_NAME=${2:-github.com/jackc/pgx/v4}
PACKAGE_PATH=https://github.com/jackc/pgx/
PACKAGE_VERSION=${1:-v4.8.1}

#install dependencies
yum install -y  go git dnf

#removed old data 
rm -rf /var/lib/pgsql/
dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf -y install postgresql13-server postgresql13-contrib
postgresql-13-setup initdb
systemctl enable --now postgresql-13
#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go/

chmod 777 /var/lib/pgsql/
if ! go get -d $PACKAGE_NAME@$PACKAGE_VERSION; then
                echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
                exit 0
fi
cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION)

echo `pwd`

chmod -R 777 /home/tester/go/
# Ensure go.mod file exists
if [ -f "go.mod" ];
then
	rm go.mod go.sum
fi
	go mod init $PACKAGE_NAME
	go mod tidy

echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"

sudo -u postgres bash <<EOF
	#set GO PATH
	export PATH=$PATH:/bin/go/bin
	export GOPATH=/home/tester/go/
		# create database for testing
		psql
		create database pgx_test;
		\c pgx_test;
		create domain uint64 as numeric(20,0);
		\q

	export PGX_TEST_DATABASE="host=/var/run/postgresql database=pgx_test"
	cd $GOPATH/pkg/mod/$PACKAGE_NAME@$PACKAGE_VERSION/
	echo `pwd`
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
