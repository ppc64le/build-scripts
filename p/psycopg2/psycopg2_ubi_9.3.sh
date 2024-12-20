#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : psycopg2
# Version       : 2.9.3
# Source repo   : https://github.com/psycopg/psycopg2
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek sharma <Vivek.Sharma20@ibm.com>
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
PACKAGE_VERSION=${1:-'2_9_3'}
PACKAGE_URL=https://github.com/psycopg/psycopg2
 
# Install required system packages
yum install -y wget
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
 
 
yum install -y git python3 python3-devel.ppc64le gcc gcc-c++ postgresql postgresql-devel postgresql-server make readline-devel zlib-devel patch libffi libffi-devel openssl openssl-devel bzip2 bzip2-devel sqlite sqlite-devel xz xz-devel --nobest
 
 
# Clone the package repository
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install Dependencies
pip install wheel
pip install .

 
# Install the package (psycopg2) using setup.py
if ! python3 setup.py install; then
  echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
  su - postgres -c '/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data stop'
  exit 1
fi
 
#We are skipping the test cases due to nearly 700 failures on both x86 and Power platforms.
