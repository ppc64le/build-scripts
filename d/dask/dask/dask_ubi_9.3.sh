#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : dask
# Version          : 2.20.0
# Source repo      : https://github.com/dask/dask.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rakshith B R <rakshith.r5@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=dask
PACKAGE_VERSION=${1:-2.20.0}  # Default version set to 2.20.0
PACKAGE_URL=https://github.com/dask/dask.git
VENV_DIR="dask_env"

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make wget python3-devel python3-pip libyaml-devel

# Create a virtual environment
# python3 -m venv $VENV_DIR
# if [ ! -f "$VENV_DIR/bin/activate" ]; then
#     echo "Failed to create virtual environment at $VENV_DIR"
#     exit 1
# fi

# Activate the virtual environment
# source "$VENV_DIR/bin/activate"

# Upgrade pip and install setuptools, wheel
pip install --upgrade pip setuptools wheel

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION  

# Install Dask
pip install -e .

# Add the virtual environment's bin directory to PATH
export PATH="/$VENV_DIR/bin:$PATH"

# Build and install the package
if ! python3 setup.py install; then
    echo "------------------$PACKAGE_NAME: Install failed-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Failed"
    exit 1
fi

echo "$PACKAGE_NAME installed successfully!"
