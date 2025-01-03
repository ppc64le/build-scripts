#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : poetry
# Version          : 1.8.3
# Source repo      : https://github.com/python-poetry/poetry.git
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
PACKAGE_NAME=poetry
PACKAGE_VERSION=${1:-1.8.3}
PACKAGE_URL=https://github.com/python-poetry/poetry.git

#install dependencies
yum install -y --allowerasing python-pip python-devel git gcc gcc-c++ make curl openssl openssl-devel wget openssl-devel bzip2-devel libffi-devel zlib-devel

# Create a symbolic link for python3
ln -s /usr/bin/python3 /usr/bin/python

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"  # Update environment variables to use Rust
else
    echo "Rust is already installed."
fi

# clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#check if requests is already installed
if pip list | grep -q "requests"; then
    echo "Removing existing requests package..."
    yum remove -y python3-requests
else
    echo "Requests package not found, no need to remove."
fi

# Install required Python packages
pip install pytest==7.1.2 httpretty keyring
pip install pytest-xdist mocker pytest-mock deepdiff

#install
if ! python3 -m pip install .; then
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
