#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : certipy
# Version          : main
# Source repo      : https://github.com/LLNL/certipy.git
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
PACKAGE_NAME=certipy
PACKAGE_VERSION=${1:-main}
PACKAGE_URL=https://github.com/LLNL/certipy.git

# Install dependencies
yum install -y --allowerasing yum-utils git gcc gcc-c++ make curl openssl-devel python3-pip python3-devel pkg-config

# Check if Python version is empty or less than 3.7
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
if [ -z "$PYTHON_VERSION" ] || [ "$(printf '%s\n' "3.7" "$PYTHON_VERSION" | sort -V | head -n1)" != "3.7" ]; then
    yum install -y python3 
else
    echo "Python version is $PYTHON_VERSION, requirement already satisfied."
fi

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"  
else
    echo "Rust is already installed."
fi

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION  

# Upgrade pip and install necessary Python packages
python3 -m pip install --upgrade pip
python3 -m pip install build wheel setuptools pypandoc requests flask pytest

# Install the package
if ! python3 -m pip install -e .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
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
