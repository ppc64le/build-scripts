#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : alembic
# Version       : rel_1_13_1
# Source repo   : https://github.com/zzzeek/alembic.git
# Tested on     : UBI 8.7
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : govind.jadhav3@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


set -e


PACKAGE_NAME=alembic
PACKAGE_VERSION=${1:-rel_1_13_1}
PACKAGE_URL=https://github.com/zzzeek/alembic.git



yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
yum install -y gcc gcc-c++ git python3.9  postgresql13-server python39-devel.ppc64le
pip3 install pytest tox  \
        pytest-xdist pytest-cov SQLAlchemy black==24.1.1 mako

#clone the repo.
ln -s /usr/bin/python3 /usr/bin/python
git clone  $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION




python setup.py build || ret=$?
# Build step for a Python project
python3 setup.py build || ret=$?

if [ "$ret" -ne 0 ]
then
  echo "FAIL: Build failed."
"bash.sh" 67L, 1596C
  exit 1
fi

# Install step for a Python project
python3 setup.py install || ret=$?

if [ "$ret" -ne 0 ]
then
  echo "FAIL: Install failed."
  exit 1
fi




#python3 -m pip install -r ./alembic/tests/requirements.txt
#note few tests are failing
#exit 2
tox  
echo "Build and tests Successful!"


