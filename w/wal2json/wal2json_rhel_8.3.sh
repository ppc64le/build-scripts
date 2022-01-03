# ---------------------------------------------------------------------
# 
# Package       : wal2json12
# Version       : wal2json_2_3
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/eulerto/wal2json.git
PACKAGE_VERSION=wal2json_2_3

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
yum update -y
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
#install dependencies
yum install -y wget make git gcc gcc-c++ libpq5-devel.ppc64le \
 system-rpm-config postgresql13-server postgresql13-devel
#export the path

export PATH=/usr/pgsql-13/bin/:$PATH

#clone the repo
git clone $REPO
cd wal2json/
git checkout $PACKAGE_VERSION
#build and install the repo.
make && make install
#permission
chmod 777 regression.out  regression.diffs results/
#start the postgres server.
su postgres
/usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ init
/usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;
/usr/pgsql-13/bin/createdb -T template0 postgres-extension;

#test 
#Note: All test cases are failing on both power and intel VM.
make installcheck
