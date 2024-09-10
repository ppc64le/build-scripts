#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : poetry-plugin-export
# Version          : 1.8.0
# Source repo      : https://github.com/python-poetry/poetry-plugin-export.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

#variables
PACKAGE_NAME=poetry-plugin-export
PACKAGE_VERSION=${1:-1.8.0}
PACKAGE_URL=https://github.com/python-poetry/poetry-plugin-export.git

#install dependencies
yum install -y --allowerasing python3-pip python3-devel git gcc gcc-c++ make curl openssl openssl-devel wget openssl-devel bzip2-devel libffi-devel zlib-devel

# clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Check if Python version is empty or less than or equal to 3.8
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
if [ -z "$PYTHON_VERSION" ] || [ "$(printf '%s\n' "3.8" "$PYTHON_VERSION" | sort -V | head -n1)" != "3.8" ]; then
    yum install -y python3
else
    echo "Python version is $PYTHON_VERSION, requirement already satisfied."
fi

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"  # Update environment variables to use Rust
else
    echo "Rust is already installed."
fi

# Upgrade pip
python3 -m pip install --upgrade pip

#check if requests is already installed
if pip list | grep -q "requests"; then
    echo "Removing existing requests package..."
    yum remove -y python3-requests
else
    echo "Requests package not found, no need to remove."
fi

# Install required Python packages 
pip install .
pip install pytest-xdist mocker pytest-mock 

#install
if ! pyproject-build; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
