#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : keyring
# Version       : 25.2.0
# Source repo : https://github.com/jaraco/keyring
# Tested on     : CentOS 7
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
#             platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such a case, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
 
# Variables
PACKAGE_NAME=keyring
PACKAGE_VERSION=25.2.0
PACKAGE_URL=https://github.com/jaraco/keyring
TARBALL_URL=https://files.pythonhosted.org/packages/b8/09/fdd3a390518e3aebeec0d7aceae7f9152da1fd2484f12f1b3a12a74aa079/keyring-25.2.0.tar.gz
 
# Install dependencies
yum install -y --allowerasing yum-utils git gcc gcc-c++ make curl python3 python3-pip python3-devel openssl-devel pkg-config
 
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
 
# Upgrade pip, setuptools, and wheel
pip install --upgrade pip setuptools wheel
 
# Install additional Python packages
pip install build pytest
 
# Download and extract the keyring source tarball
curl -O $TARBALL_URL
tar -xvzf keyring-25.2.0.tar.gz
cd keyring-25.2.0
 
# Install the keyring package in editable mode
pip install -e .
 
# Build the project
if ! python3 -m build; then
    echo "------------------$PACKAGE_NAME: Install_fails ---------------------"
    exit 1
fi
 
# Run tests using pytest
if ! pytest -v tests/; then
    echo "------------------$PACKAGE_NAME: Install_success_but_test_fails -----"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install_&_test_both_success --------"
    exit 0
fi
