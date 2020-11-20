# ----------------------------------------------------------------------------
#
# Package       : logbook
# Version       : 1.0.0
# Source repo   : https://github.com/getlogbook/logbook
# Tested on     : RHEL 7.6, RHEL 7.7
# Script License: Apache License, Version 2 or later
# Maintainer    : Ryan D'Mello <ryan.dmello1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export PYTHON=python3
export PIP=pip3
export LANG=en_US.utf8
export PACKAGE_VERSION=1.0.0
export PACKAGE_NAME=logbook
export PACKAGE_URL=https://github.com/getlogbook/logbook
WDIR=`pwd`

yum update -y
yum-config-manager --enable rhel-7-for-power-le-optional-rpms
yum install -y python3 python3-pip git gcc gcc-devel gcc-c++ python3-devel

# Install additional dependencies
${PIP} install cython

git clone ${PACKAGE_URL} ${PACKAGE_NAME} -b ${PACKAGE_VERSION}
cd ${PACKAGE_NAME}
cython logbook/_speedups.pyx
sed -i '141d' setup.py && sed -i '141i\            \self.default_options)' setup.py
${PYTHON} setup.py install
${PYTHON} setup.py test

# Test logbook installation
