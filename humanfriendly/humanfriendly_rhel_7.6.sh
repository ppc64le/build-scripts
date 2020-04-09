# ----------------------------------------------------------------------------
#
# Package       : humanfriendly
# Version       : 8.1
# Source repo   : https://github.com/xolox/python-humanfriendly
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
export PACKAGE_VERSION=8.1
export PACKAGE_NAME=humanfriendly
export PACKAGE_URL=https://github.com/xolox/python-humanfriendly
WDIR=`pwd`

yum update -y
yum install -y python3 python3-pip git 

# Install additional dependencies
${PIP} install docutils mock

git clone ${PACKAGE_URL} ${PACKAGE_NAME} -b ${PACKAGE_VERSION}
cd ${PACKAGE_NAME}
${PIP} install -r requirements.txt
${PYTHON} setup.py install
${PYTHON} setup.py test

# Verify humanfriendly installation
${PYTHON} -c "import humanfriendly;user_input = \"16GB\";num_bytes = humanfriendly.parse_size(user_input);print (num_bytes);print (\"You entered:\", humanfriendly.format_size(num_bytes))"