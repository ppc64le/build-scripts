# ----------------------------------------------------------------------------
#
# Package       : xlsxwriter
# Version       : 3.0.2
# Source repo   : https://github.com/jmcnamara/XlsxWriter.git
# Tested on     : RHEL 7.6, RHEL 7.7
# Language      : Python
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
export PACKAGE_VERSION=RELEASE_3.0.2
export PACKAGE_NAME=xlsxwriter
export PACKAGE_URL=https://github.com/jmcnamara/XlsxWriter.git

yum update -y
yum install -y yum-utils
yum-config-manager --enable rhel-7-for-power-le-optional-rpms
yum install -y python3 python3-devel python3-pip git

git clone ${PACKAGE_URL} ${PACKAGE_NAME} -b ${PACKAGE_VERSION}
cd ${PACKAGE_NAME}

${PYTHON} setup.py install
${PYTHON} setup.py test

# Test xlsxwriter installation
