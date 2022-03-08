#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : lib/pq
# Version       : v1.5.1
# Source repo   : https://github.com/lib/pq
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
#Run the script:./pq_rhel_8.2.sh v1.5.1(version_to_test)
PACKAGE_NAME=pq
PACKAGE_VERSION=${1:-v1.5.1}
POSTGRES_VERSION=11
GO_VERSION=1.16.1
PACKAGE_URL=https://github.com/lib/pq.git

dnf install git wget sudo -y
rm -rf /var/lib/pgsql/*
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql$POSTGRES_VERSION-server
sudo /usr/pgsql-$POSTGRES_VERSION/bin/postgresql-$POSTGRES_VERSION-setup initdb
sudo systemctl enable postgresql-$POSTGRES_VERSION
sudo systemctl start postgresql-$POSTGRES_VERSION

mkdir -p /home/tester/output
cd /home/tester

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf /home/tester/go && tar -C /home/tester -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export GOPATH=/home/tester/go
export PATH=$PATH:$GOPATH/bin




#Configure postgres database
sudo chmod 777 /var/lib/pgsql/$POSTGRES_VERSION/data/pg_hba.conf
echo "local     all         postgres                          trust"    >  /var/lib/pgsql/$POSTGRES_VERSION/data/pg_hba.conf
echo "local     all         all                               trust"    >> /var/lib/pgsql/$POSTGRES_VERSION/data/pg_hba.conf
echo "host      all         pgx_md5     127.0.0.1/32          md5"      >> /var/lib/pgsql/$POSTGRES_VERSION/data/pg_hba.conf
echo "host      all         pgx_pw      127.0.0.1/32          password" >> /var/lib/pgsql/$POSTGRES_VERSION/data/pg_hba.conf
echo "hostssl   all         pgx_ssl     127.0.0.1/32          md5"      >> /var/lib/pgsql/$POSTGRES_VERSION/data/pg_hba.conf
echo "host      replication pgx_replication 127.0.0.1/32      md5"      >> /var/lib/pgsql/$POSTGRES_VERSION/data/pg_hba.conf
echo "host      pgx_test pgx_replication 127.0.0.1/32      md5"      >> /var/lib/pgsql/$POSTGRES_VERSION/data/pg_hba.conf

#Restart
sudo systemctl restart postgresql-$POSTGRES_VERSION

psql -U postgres -c 'create database pgx_test'
psql -U postgres pgx_test -c 'create domain uint64 as numeric(20,0)'
psql -U postgres -c "create user pgx_ssl SUPERUSER PASSWORD 'secret'"
psql -U postgres -c "create user pgx_md5 SUPERUSER PASSWORD 'secret'"
psql -U postgres -c "create user pgx_pw  SUPERUSER PASSWORD 'secret'"
psql -U postgres -c "create user `whoami`"
psql -U postgres -c "create user pgx_replication with replication password 'secret'"
psql -U postgres -c "create user \" tricky, ' } \"\" \\ test user \" superuser password 'secret'" 

rm -rf $PACKAGE_NAME

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


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
if ! PGHOST=127.0.0.1 PGPORT=5432 PGUSER=pgx_pw PGSSLMODE=disable PGDATABASE=pgx_test PGPASSWORD=secret go test -v; then
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


