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

#!/bin/bash

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

#Build and test the package
#Note: Three test cases are failing on both architecture power and intel.
tox