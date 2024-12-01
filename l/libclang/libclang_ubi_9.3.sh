#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : libclang
# Version          : 14.0.6
# Source repo      : https://github.com/sighingnow/libclang.git
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
PACKAGE_NAME=libclang
PACKAGE_VERSION=${1:-llvm-14.0.6}
PACKAGE_URL=https://github.com/sighingnow/libclang.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python3-devel python3-pip cmake xz

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install llvm dependencies if not already installed
if ! yum list installed clang &>/dev/null; then
    echo "Clang not found. Installing Clang..."
    yum install -y clang
else
    echo "Clang is already installed."
fi

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"  # Update environment variables to use Rust
else
    echo "Rust is already installed."
fi

# Install additional Python dependencies
pip install pytest setuptools tox wheel

# Install the package
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
if ! tox -v; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
        exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
