#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : SQLAlchemy
# Version        : 1.4.39
# Source repo    : https://github.com/sqlalchemy/sqlalchemy.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : vivek sharma<vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=sqlalchemy
PACKAGE_VERSION=rel_1_4_39
PACKAGE_URL=https://github.com/sqlalchemy/sqlalchemy.git

# Install necessary system packages
yum install -y git gcc gcc-c++ make wget sudo openssl-devel bzip2-devel libffi-devel zlib-devel sqlite-devel
yum install -y pip

# Upgrade pip and install necessary Python packages
pip3 install greenlet
pip3 install --upgrade pip setuptools wheel
pip3 install pytest

# Add /usr/local/bin to PATH
export PATH=$PATH:/usr/local/bin/

# Clone the repository
git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

# Set up a virtual environment
python3 -m venv env
source env/bin/activate

# Upgrade pip and setuptools within the virtual environment
pip install --upgrade pip setuptools wheel

# Enable legacy editable mode for setuptools
export SETUPTOOLS_ENABLE_FEATURES="legacy-editable"

# Install the package in editable mode with testing dependencies
pip install -e .[testing]

# Check if setup.py file exists and install the package
if [ -f "setup.py" ]; then
    if ! python3 setup.py install; then
        echo "------------------${PACKAGE_NAME}: Install_fails------------------"
        echo "${PACKAGE_URL} ${PACKAGE_NAME}"
        echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
        exit 1
    fi
    echo "setup.py file exists"
else
    echo "setup.py not present"
fi

# Run tests using pytest
if command -v pytest &> /dev/null; then
    if ! pytest; then
        echo "------------------${PACKAGE_NAME}: Tests_Fail------------------"
        echo "${PACKAGE_URL} ${PACKAGE_NAME}"
        echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Tests_Fail"
        exit 1
    fi
else
    echo "pytest is not installed or not found in PATH"
    exit 1
fi

# Deactivate the virtual environment
deactivate
