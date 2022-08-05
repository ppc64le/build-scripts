# ------------------------------------------------------------------------------------------------
#
# Package       : psycopg2cffi
# Version       : 2.8.1, 2.9.0
# Source repo   : https://github.com/chtd/psycopg2cffi.git
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
# Instructions	: 1. Run the docker conatiner as: 
#		  docker run -t -d --privileged registry.access.redhat.com/ubi8/ubi /usr/sbin/init
#		  If the docker container is already running remove the script code under...
#		  #Install postgres and run tests
#		  2. Connect to the docker container
#		  docker exec -it <container id> bash
#		  3. Run this script
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------------------------------

#!/bin/bash

#Variables
REPO=https://github.com/chtd/psycopg2cffi.git
PACKAGE_VERSION=2.9.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 2_8_6 for 2.8.6"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install required packages
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum -y install epel-release sudo python3-devel libpq-devel libffi-devel git gcc

#Clone and checkout the package
cd /opt
git clone $REPO
cd psycopg2cffi/
git checkout $PACKAGE_VERSION

#Build and install package
python3 setup.py install

#Install postgres and run tests
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf install -y postgresql13-server
/usr/pgsql-13/bin/postgresql-13-setup initdb
systemctl enable postgresql-13
systemctl start postgresql-13
pip3 install -U pytest
sudo -u postgres -i bash << EOF
psql -c "CREATE DATABASE psycopg2_test;"
cd /opt/psycopg2cffi/
/usr/local/bin/py.test psycopg2cffi
EOF
echo "Installation complete, one faling test (test_types_basic.py::TypesBasicTests::testEmptyArray) is in parity with x86."
