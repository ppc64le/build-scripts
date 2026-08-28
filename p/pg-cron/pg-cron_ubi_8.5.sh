#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: pg_cron
# Version	: v1.3.1
# Source repo	: https://github.com/citusdata/pg_cron
# Tested on	: ubi 8.5
# Language      : c
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="pg_cron"
PACKAGE_VERSION=${1:-"v1.3.1"}
PACKAGE_URL="https://github.com/citusdata/pg_cron"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
home_dir="$PWD"

dnf install -qy https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
dnf install -qy perl-CPAN redhat-rpm-config postgresql13-devel postgresql13-contrib postgresql13-server patch diffutils git gcc-c++ make sudo
export PERL_MM_USE_DEFAULT=1
cpan TAP::Parser::SourceHandler::pgTAP
postgresql-13-setup initdb
systemctl start postgresql-13
sudo -u postgres createuser -s $(whoami)
sudo -u postgres createdb  $(whoami)
psql -c "alter user postgres password '1234';"
export PGPASSWORD=1234
export PGHOST=localhost
export PGPORT=5432
export PGUSER=postgres
export PGSSLMODE=disable
export PGDATABASE=postgres
export PATH=$PATH:/usr/pgsql-13/bin

git clone -q https://github.com/theory/pgtap
cd pgtap
git checkout "335e3187422c5359df5b297b219d4dd832750af9"
make install
psql -c "create extension pgtap;"
cd -
git clone -q $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
make install
export POSTGRES_CONF=$(psql -t -c "show config_file;" | xargs echo)
echo "shared_preload_libraries = 'pg_cron'" >>$POSTGRES_CONF
echo "cron.database_name = 'postgres'" >>$POSTGRES_CONF
sudo -u postgres /usr/pgsql-13/bin/pg_ctl restart -D /var/lib/pgsql/13/data/
psql -c "create extension pg_cron;"
make installcheck
