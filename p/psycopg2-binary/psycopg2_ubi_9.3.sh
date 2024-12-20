#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : psycopg2
# Version       : 2.9.9
# Source repo   : https://github.com/psycopg/psycopg2
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pranith Rao <Pranith.Rao@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 
PACKAGE_NAME=psycopg2
PACKAGE_VERSION=${1:-'2.9.9'}
PACKAGE_URL=https://github.com/psycopg/psycopg2

yum install -y wget
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum remove -y python-chardet

yum install -y git python3 python3-devel.ppc64le gcc gcc-c++ postgresql postgresql-devel postgresql-server make readline-devel zlib-devel patch libffi libffi-devel openssl openssl-devel bzip2 bzip2-devel sqlite sqlite-devel xz xz-devel --nobest
yum remove -y python-chardet
 
# Install & configure pyenv
curl https://pyenv.run | bash
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
 
# Installing required Python versions
pyenv install 3.7.12
pyenv install 3.8.12
pyenv install 3.9.12
pyenv install 3.10.12
pyenv install 3.11.4
pyenv install 3.12.0

pyenv global 3.7.12 3.8.12 3.9.12 3.10.12 3.11.4 3.12.0
pip3 install tox setuptools packaging
 
export PATH=$PATH:/usr/local/bin/
export PG_CONFIG=/usr/bin/pg_config
export PSYCOPG2_TESTDB="psycopg2_test"
export PSYCOPG2_TESTDB_USER="postgres"
export PSYCOPG2_TESTDB_HOST="/tmp"
 
# PostgreSQL DB setup for testcases
cd /tmp
wget https://ftp.postgresql.org/pub/source/v13.4/postgresql-13.4.tar.gz
tar xzf postgresql-13.4.tar.gz
cd postgresql-13.4
./configure
make
make install

mkdir /usr/local/pgsql/data
chown postgres /usr/local/pgsql/data
su - postgres -c '/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data'
sed -i "s/#unix_socket_directories = '\/tmp'/unix_socket_directories = '\/tmp'/" /usr/local/pgsql/data/postgresql.conf
su - postgres -c '/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l logfile start'
su - postgres -c 'createdb -h /tmp/ psycopg2_test'

cd /
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python3 setup.py install; then
  echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
  su - postgres -c '/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data stop'
  exit 1
fi
 
# Modify tox.ini for the environment
sed -i '7s/passenv = PG\* PSYCOPG2_TEST\*/passenv = PG*, PSYCOPG2_TEST*/' tox.ini
sed -i '/\[testenv\]/a allowlist_externals = make' tox.ini

if ! tox -- -h /tmp/; then
  echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
  su - postgres -c '/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data stop'
  exit 2
else
  echo "------------------$PACKAGE_NAME:Install_&_test_both_success------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
  su - postgres -c '/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data stop'
  exit 0
fi