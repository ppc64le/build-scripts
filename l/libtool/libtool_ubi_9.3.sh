#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : libtool
# Version          : master
# Source repo      : https://github.com/matan-h/libtool.git
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
PACKAGE_NAME=libtool
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/matan-h/libtool.git

# Install dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION  

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"  
else
    echo "Rust is already installed."
fi

# Upgrade pip and install necessary Python packages
pip install --upgrade pip wheel setuptools tox

#install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases
if !(python3 -m unittest discover -p "test_*.py"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
