#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: pgnodemx
# Version	: 1.3.0
# Source repo	: https://github.com/CrunchyData/pgnodemx
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

PACKAGE_NAME="pgnodemx"
PACKAGE_VERSION=${1:-"1.3.0"}
PACKAGE_URL="https://github.com/CrunchyData/pgnodemx"

dnf install -qy https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
dnf install -qy perl-CPAN redhat-rpm-config postgresql13-devel postgresql13-contrib postgresql13-server patch diffutils git gcc-c++ make sudo openssl-devel

postgresql-13-setup initdb
systemctl start postgresql-13
sudo -u postgres createuser -s "$(whoami)"
sudo -u postgres createdb "$(whoami)"
psql -c "alter user postgres password '1234';"
export USE_PGXS=1
export PGPASSWORD=1234
export PGHOST=localhost
export PGPORT=5432
export PGUSER=postgres
export PGSSLMODE=disable
export PGDATABASE=postgres
export PATH=$PATH:/usr/pgsql-13/bin
git clone -q $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"
make install
export POSTGRES_CONF=$(psql -t -c "show config_file;" | xargs echo)
echo "shared_preload_libraries = 'pgnodemx'" >>"$POSTGRES_CONF"

sudo -u postgres /usr/pgsql-13/bin/pg_ctl restart -D /var/lib/pgsql/13/data/
psql -c "create extension pgnodemx;"
make installcheck
