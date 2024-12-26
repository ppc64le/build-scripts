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
# Maintainer     : Vivek sharma<vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=sqlalchemy
PACKAGE_VERSION=rel_1_4_39
PACKAGE_URL=https://github.com/sqlalchemy/sqlalchemy.git

# Install necessary system packages
yum install -y git gcc gcc-c++ make wget sudo openssl-devel bzip2-devel libffi-devel zlib-devel sqlite-devel

# Install Python 3.10
cd /usr/src
wget https://www.python.org/ftp/python/3.10.8/Python-3.10.8.tgz
tar xzf Python-3.10.8.tgz
cd Python-3.10.8
./configure --enable-optimizations
make altinstall
cd ..

# Verify Python 3.10 installation
python3.10 --version || { echo "Python 3.10 installation failed"; exit 1; }

# Set Python 3.10 as the default python3
alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.10 1
alternatives --set python3 /usr/local/bin/python3.10

# Upgrade pip and install necessary Python packages
python3.10 -m ensurepip
python3.10 -m pip install --upgrade pip setuptools wheel greenlet pytest

# Clone the repository
git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

# Set up a virtual environment
python3.10 -m venv env
source env/bin/activate

# Upgrade pip and setuptools within the virtual environment
pip install --upgrade pip setuptools wheel

# Enable legacy editable mode for setuptools
export SETUPTOOLS_ENABLE_FEATURES="legacy-editable"

# Install the package in editable mode with testing dependencies
pip install -e .[testing]

# Check if setup.py file exists and install the package
if [ -f "setup.py" ]; then
    if ! python3.10 setup.py install; then
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
