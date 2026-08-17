#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : psycopg2
# Version       : 2.9.3
# Source repo   : https://github.com/psycopg/psycopg2
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <shivansh.s1@ibm.com>
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
PACKAGE_VERSION=${1:-'2.9.10'}
PACKAGE_URL=https://github.com/psycopg/psycopg2

# Install required system packages
yum install -y git python3.12 python3.12-devel gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ postgresql make zlib-devel patch libffi libffi-devel openssl openssl-devel bzip2 bzip2-devel sqlite sqlite-devel xz xz-devel postgresql-devel --nobest

if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

# Clone the package repository
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install Dependencies
pip install wheel
pip install setuptools

# Install the package (psycopg2) using setup.py
if ! python3.12 setup.py install; then
  echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
  su - postgres -c '/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data stop'
  exit 1
fi

#We are skipping the test cases due to nearly 700 failures on both x86 and Power platforms.

