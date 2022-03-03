#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pgtype
# Version       : v1.3.0
# Source repo   : https://github.com/jackc/pgtype.git
# Tested on     : rhel 8.2
# Language      : go
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer    : Sachin K {sachin.kakatkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./pgtype_rhel_8.2.sh v1.3.0(version_to_test)
PACKAGE_NAME=pgtype
PACKAGE_VERSION=v1.3.0
PACKAGE_URL=https://github.com/jackc/pgtype.git

dnf install git wget sudo -y
rm -rf /var/lib/pgsql/*
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql10-server
sudo /usr/pgsql-10/bin/postgresql-10-setup initdb
sudo systemctl enable postgresql-10
sudo systemctl start postgresql-10

#sudo su - postgres
sudo chmod 777 /var/lib/pgsql/10/data/pg_hba.conf
echo "local     all         postgres                          trust"    >  /var/lib/pgsql/10/data/pg_hba.conf
echo "local     all         all                               trust"    >> /var/lib/pgsql/10/data/pg_hba.conf
echo "host      all         pgx_md5     127.0.0.1/32          md5"      >> /var/lib/pgsql/10/data/pg_hba.conf
echo "host      all         pgx_pw      127.0.0.1/32          password" >> /var/lib/pgsql/10/data/pg_hba.conf
echo "hostssl   all         pgx_ssl     127.0.0.1/32          md5"      >> /var/lib/pgsql/10/data/pg_hba.conf
echo "host      replication pgx_replication 127.0.0.1/32      md5"      >> /var/lib/pgsql/10/data/pg_hba.conf
echo "host      pgx_test pgx_replication 127.0.0.1/32      md5"      >> /var/lib/pgsql/10/data/pg_hba.conf

sudo systemctl restart postgresql-10

psql -U postgres -c 'create database pgx_test'
psql -U postgres pgx_test -c 'create domain uint64 as numeric(20,0)'
psql -U postgres -c "create user pgx_ssl SUPERUSER PASSWORD 'secret'"
psql -U postgres -c "create user pgx_md5 SUPERUSER PASSWORD 'secret'"
psql -U postgres -c "create user pgx_pw  SUPERUSER PASSWORD 'secret'"
psql -U postgres -c "create user `whoami`"
psql -U postgres -c "create user pgx_replication with replication password 'secret'"
psql -U postgres -c "create user \" tricky, ' } \"\" \\ test user \" superuser password 'secret'" 



PACKAGE_VERSION=${1:-v1.3.0}

# Install Go and setup working directory
wget https://golang.org/dl/go1.16.1.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.16.1.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p /home/tester/output
cd /home/tester

rm -rf $PACKAGE_NAME

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

INSTALL_SUCCESS="false"


if ! go build; then
        INSTALL_SUCCESS="false"
        else
        INSTALL_SUCCESS="true"
fi

# Ensure go.mod file exists
if ! PGX_TEST_DATABASE="host=127.0.0.1 database=pgx_test user=pgx_pw password=secret sslmode=disable" go test -v -race ./...; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi

#3 test cases failed and result parity with intel
#TestXIDAssignTo
#TestHstoreArrayTranscode
#TestHstoreTranscode

