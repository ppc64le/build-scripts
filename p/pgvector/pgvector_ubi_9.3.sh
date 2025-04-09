#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#
# Package	: pgvector
# Version	: v0.7.4
# Source repo	: https://github.com/pgvector/pgvector
# Tested on	: UBI 9.3
# Language      : C
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e 
SCRIPT_PACKAGE_VERSION=v0.7.4
PACKAGE_NAME=pgvector
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/pgvector/pgvector.git
POSTGRES_SOURCE_URL=https://ftp.postgresql.org/pub/source/v16.4/postgresql-16.4.tar.gz
POSTGRES_SOURCE=postgresql-16.4.tar.gz
POSTGRES_FOLDER=postgresql-16.4
BUILD_HOME=$(pwd)

# Install update and deps
yum update -y
yum install -y make g++ wget git libpq-devel python3-devel.ppc64le python-psycopg2 zlib-devel libicu-devel


# Change to home directory
cd $BUILD_HOME

# Change root password
echo "root:lormipsum" | chpasswd

# Download and extract PostgreSQL source
wget  $POSTGRES_SOURCE_URL
tar xf $POSTGRES_SOURCE
cd $POSTGRES_FOLDER

# Configure, compile, and install PostgreSQL
./configure --without-readline --prefix=/local/apps/postgresql/pgsql164/ --with-pgport=5432
make
make install

# Add postgres user and set password
useradd -d /home/postgres/ postgres
echo "postgres:lormipsum" | chpasswd

# Setup PostgreSQL data directory
mkdir -p /local/apps/postgresql/pgsql164/data
chown postgres /local/apps/postgresql/pgsql164/data

# Initialize and start PostgreSQL
su - postgres -c "/local/apps/postgresql/pgsql164/bin/initdb -D /local/apps/postgresql/pgsql164/data"
su - postgres -c "/local/apps/postgresql/pgsql164/bin/pg_ctl -D /local/apps/postgresql/pgsql164/data -l logfile start"

# Update environment variables
su - postgres -c "echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/local/apps/postgresql/pgsql164/lib' >> /home/postgres/.bash_profile"
su - postgres -c "echo 'export PATH=$PATH:/local/apps/postgresql/pgsql164/bin' >> /home/postgres/.bash_profile"
su - postgres -c "source /home/postgres/.bash_profile"

# Verify psql installation
su - postgres -c "which psql"
cd ..

# Clone pgvector repository
su - postgres -c "git clone $PACKAGE_URL && cd $PACKAGE_NAME && git checkout $PACKAGE_VERSION && sed -i 's/pg_config/\/local\/apps\/postgresql\/pgsql164\/bin\/pg_config/' Makefile"

# Build and install pgvector
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
sed -i 's/pg_config/\/local\/apps\/postgresql\/pgsql164\/bin\/pg_config/' Makefile
# make
if ! make ; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_Fails"
    exit 1
fi
# make install
if ! make install; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run install check
# su - postgres -c "cd pgvector && make installcheck"

if ! su - postgres -c "cd pgvector && make installcheck"; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

export PGVECTOR_Build='/local/apps/postgresql/pgsql164/lib/vector.so'

echo "PostgreSQL and pgvector installation completed."
echo "pgvector installation check completed."
echo "pgvector bit binary is available at [$PGVECTOR_Build]."
