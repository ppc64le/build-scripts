#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pgtype
# Version          : v1.14.2
# Source repo      : https://github.com/jackc/pgtype
# Tested on        : UBI 8.7
# Language         : Go
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=pgtype
PACKAGE_VERSION=${1:-v1.14.2}
PACKAGE_URL=https://github.com/jackc/pgtype

yum install -y sudo git wget gcc gcc-c++ 

#intall postgresql server for tests
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf install -y postgresql16-server postgresql16-contrib
sudo -u postgres /usr/pgsql-16/bin/initdb -D /var/lib/pgsql/16/data
sudo -u postgres /usr/pgsql-16/bin/pg_ctl -D /var/lib/pgsql/16/data start

#install go
wget https://go.dev/dl/go1.21.6.linux-ppc64le.tar.gz
tar -C  /usr/local -xf go1.21.6.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Create a database,password,extension and type for the postgresql tests
psql -U postgres -p 5432 -c 'create database pgx_test' || true
psql -U postgres -p 5432 -c "create user pgx_pw  SUPERUSER PASSWORD 'secret'" || true
psql "host=127.0.0.1 dbname=pgx_test user=postgres password=secret sslmode=disable" -c "CREATE EXTENSION hstore;"
psql "host=127.0.0.1 dbname=pgx_test user=postgres password=secret sslmode=disable" -c "CREATE EXTENSION ltree;"
psql "host=127.0.0.1 dbname=pgx_test user=postgres password=secret sslmode=disable" -c "CREATE TYPE int8multirange AS RANGE (subtype = bigint);"
psql "host=127.0.0.1 dbname=pgx_test user=postgres password=secret sslmode=disable" -c "CREATE TYPE int4multirange AS RANGE (subtype = bigint);"

if ! go build ./... ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! PGX_TEST_DATABASE="host=127.0.0.1 port=5432 database=pgx_test user=pgx_pw password=secret sslmode=disable" go test -v ./... ; then
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
