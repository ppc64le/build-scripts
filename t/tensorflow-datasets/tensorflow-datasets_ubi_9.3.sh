#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : tensorflow-datasets
# Version       : v4.9.4
# Source repo   : https://github.com/tensorflow/datasets.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=datasets
PACKAGE_VERSION=${1:-v4.9.4}
PACKAGE_URL=https://github.com/tensorflow/datasets.git

# Install dependencies and tools.
yum install -y gcc gcc-c++ gcc-gfortran git make  wget openssl-devel cmake zlib-devel libjpeg-devel libffi-devel

#This package required python version >=3.10

# Get the current Python version
current_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "Current Python version: $current_version"

# Check if current python version is greater than or equal to 3.10.
if python3 -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)"; then
    echo "Python version is $current_version, which is 3.10 or greater."
else
    echo "Python version is $current_version, which is less than 3.10."
    echo "Installing Python 3.10..."

    # Download and install Python 3.10
    wget https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz
    tar xzf Python-3.10.12.tgz
    cd Python-3.10.12
    ./configure --prefix=/usr/local --enable-optimizations
    make altinstall
    cd ..
    ln -sf $(which python3.10) /usr/bin/python3		
fi

#Upgrade pip
python3 -m pip install --upgrade pip

#installing array-record
git clone https://github.com/google/array_record.git 
cd array_record/
git checkout v0.5.0
pip3 install .
python3 setup.py install
cd ..

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
	 
#install
if ! ( python3 -m pip install --editable .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
