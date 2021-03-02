# ----------------------------------------------------------------------------
#
# Package       : readme_renderer
# Version       : 29.0
# Source repo   : https://github.com/pypa/readme_renderer
# Tested on     : RHEL 7.6, RHEL 7.7
# Script License: Apache License, Version 2 or later
# Maintainer    : Vedang Wartikar <vedang.wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# 	      platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export PYTHON=python3
export PIP=pip3
export LANG=en_US.utf8
export PACKAGE_VERSION=29.0
export PACKAGE_NAME=readme_renderer
export PACKAGE_URL=https://github.com/pypa/readme_renderer

yum update -y
yum install -y python3 python3-devel python3-pip git

git clone ${PACKAGE_URL} ${PACKAGE_NAME} -b ${PACKAGE_VERSION}
cd ${PACKAGE_NAME}

${PIP} install pytest
${PIP} install mock

${PYTHON} setup.py install
${PYTHON} setup.py test
