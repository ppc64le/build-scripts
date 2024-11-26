#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyspnego
# Version          : v0.10.2
# Source repo      : https://github.com/jborean93/pyspnego.git
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
PACKAGE_NAME=pyspnego
PACKAGE_VERSION=${1:-v0.10.2}
PACKAGE_URL=https://github.com/jborean93/pyspnego.git

# Install dependencies
yum install -y --allowerasing git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel curl python-pip python-devel krb5-devel

# Clone repository
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

#upgrade pip
python3 -m pip install --upgrade pip

# Install dependencies
pip install -r requirements-test.txt
pip install wheel build pytest pytest-mock mocker k5test


# Check for kdb5_util with permission handling
if [ ! -f /usr/sbin/kdb5_util ]; then
    echo "/usr/sbin/kdb5_util not found. Skipping related tests."
    export SKIP_TESTS=true
elif ! [ -x /usr/sbin/kdb5_util ]; then
    echo "No execute permission for /usr/sbin/kdb5_util. Skipping related tests."
    export SKIP_TESTS=true
fi

# Install the package
if ! python3 setup.py install; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests with skip condition
if [ "$SKIP_TESTS" = "true" ]; then
    pytest --ignore-glob='*kdb5_util*' --ignore=tests/test_auth.py --ignore=tests/test_gss.py --ignore=tests/test_auth_dce.py
else
    if ! pytest -v; then
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
fi
