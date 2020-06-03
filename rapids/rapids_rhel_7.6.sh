# ----------------------------------------------------------------------------
#
# Package       : rapids
# Version       : v0.0.1
# Source repo   : https://github.com/sinoroc/rapids
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
export PACKAGE_VERSION=v0.0.1
export PACKAGE_NAME=rapids
export PACKAGE_URL=https://github.com/sinoroc/rapids

yum update -y
yum install -y yum-utils
yum-config-manager --enable rhel-7-for-power-le-optional-rpms
yum install -y python3 python3-devel python3-pip git

git clone ${PACKAGE_URL} ${PACKAGE_NAME} -b ${PACKAGE_VERSION}
cd ${PACKAGE_NAME}

${PYTHON} setup.py install
${PYTHON} setup.py test

# Test python rake installation
