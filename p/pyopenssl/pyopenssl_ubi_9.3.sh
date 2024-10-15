#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyopenssl
# Version          : 24.1.0
# Source repo      : https://github.com/pyca/pyopenssl.git
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

# Variables
PACKAGE_NAME=pyopenssl
PACKAGE_VERSION=${1:-24.1.0}
PACKAGE_URL=https://github.com/pyca/pyopenssl.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip openssl-devel

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION  

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"  # Update environment variables to use Rust
else
    echo "Rust is already installed."
fi

#remove existing unnecessary dependency
if yum list installed python3-chardet &> /dev/null; then
    echo "python3-chardet is installed. Removing it..."
     yum remove -y python3-chardet
else
    echo "python3-chardet is not installed."
fi
 
# Upgrade pip
python3 -m pip install --upgrade pip

# Install additional dependencies
pip install .
pip install pretend flaky build tox

#install
if ! pyproject-build; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
