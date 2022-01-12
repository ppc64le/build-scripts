# -----------------------------------------------------------------------------
#
# Package       : alembic
# Version       : master
# Source repo   : https://github.com/zzzeek/alembic.git
# Tested on     : UBI 8
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
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
PACKAGE_VERSION=${1:-rel_1_7_4}
PACKAGE_URL=https://github.com/zzzeek/alembic.git 

yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
yum install -y gcc gcc-c++ git python3 python3-pip postgresql13-server python36-devel.ppc64le
pip3 install pytest tox  \
	pytest-xdist pytest-cov SQLAlchemy black mako

#clone the repo.
ln -s /usr/bin/python3 /usr/bin/python
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test the package
#Note: Three test cases are failing on both architecture power and intel.
tox
