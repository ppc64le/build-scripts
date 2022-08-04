#!/bin/bash -ex

# -----------------------------------------------------------------------------
#
# Package       : pgx
# Version       : v4.12.0
# Source repo   : https://github.com/jackc/pgx.git
# Tested on     : UBI 8.5
# Language      : go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ambuj Kumar <Ambuj.Kumar3@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pgx
PACKAGE_VERSION=${1:-v4.12.0}
PACKAGE_URL=https://github.com/jackc/pgx.git

dnf install wget git -y

cat > /etc/yum.repos.d/centos.repo<<EOF
[local-rhn-server-baseos]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server RPMs
baseurl=http://mirror.centos.org/centos/8-stream/BaseOS/\$basearch/os/
enabled=1
gpgcheck=0
[local-rhn-server-appstream]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server Supplementary RPMs
baseurl=http://mirror.centos.org/centos/8-stream/AppStream/\$basearch/os/
enabled=1
gpgcheck=0
[local-rhn-server-powertools]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server Supplementary RPMs
baseurl=http://mirror.centos.org/centos/8-stream/PowerTools/\$basearch/os/
enabled=1
gpgcheck=0
EOF

yum group install -y 'Development Tools'
yum install -y readline-devel

if [ -d "postgres" ] ; then
    rm -rf postgres
fi
# Build and install postgresql to build and test pgconn package
git clone --depth=2 -b REL_11_15 https://github.com/postgres/postgres

cd postgres
./configure
make
make install

cd contrib/hstore
make
make install
cd ../../

adduser postgres || true

if [ -d "/usr/local/pgsql/data2" ] ; then
    rm -rf /usr/local/pgsql/data2
fi
mkdir /usr/local/pgsql/data2
chown postgres:postgres /usr/local/pgsql/data2
runuser -l postgres -c '/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data2/'
runuser -l postgres -c '/usr/local/pgsql/bin/postmaster -D /usr/local/pgsql/data2 -p 5434 >logfile 2>&1' &

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y R

wget https://golang.org/dl/go1.16.1.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.16.1.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p /home/tester/output
cd /home/tester

export USE_PGXS=1
export PATH=/usr/local/pgsql/bin:$PATH

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
    rm -rf $PACKAGE_NAME
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 0
fi
cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! (go build); then
    echo "------------------$PACKAGE_NAME:build failed---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  build_Fails"
    exit 1
fi
echo $PWD

psql -U postgres -p 5434 -c 'create database pgx_test' || true
psql -U postgres pgx_test -p 5434 -c 'create domain uint64 as numeric(20,0)' || true
psql -U postgres -p 5434 -c "create user pgx_ssl SUPERUSER PASSWORD 'secret'" || true
psql -U postgres -p 5434 -c "create user pgx_md5 SUPERUSER PASSWORD 'secret'" || true
psql -U postgres -p 5434 -c "create user pgx_pw  SUPERUSER PASSWORD 'secret'" || true
psql -U postgres -p 5434 -c "create user `whoami`" || true
psql -U postgres -p 5434 -c "create user pgx_replication with replication password 'secret'" || true
psql -U postgres -p 5434 -c "create user \" tricky, ' } \"\" \\ test user \" superuser password 'secret'" || true

psql -U postgres pgx_test -p 5434 -c 'create extension hstore;' || true

if ! PGX_TEST_DATABASE="host=127.0.0.1 port=5434 database=pgx_test user=pgx_pw password=secret sslmode=disable" go test -v ./...; then
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
