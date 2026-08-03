#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jq
# Version       : 1.11.0
# Source repo   : https://github.com/mwilliamson/jq.py
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Rosman Carino <rcarino@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=jq.py
PACKAGE_VERSION=${1:-1.11.0}
PACKAGE_URL=https://github.com/mwilliamson/jq.py
PACKAGE_DIR=jq.py

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Install system dependencies
# autoconf/libtool are needed by the bundled jq-1.8.2 configure step
yum install -y git python3 python3-devel gcc-toolset-13 make wget sudo cmake autoconf libtool

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Install Python build dependencies (Cython is required by setup.py)
pip3 install "cython==3.2.3" setuptools wheel pytest

# Clone the repo
if [ -d "$PACKAGE_DIR" ]; then
    cd "$PACKAGE_DIR" || exit
else
    if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
        exit 1
    fi
    cd "$PACKAGE_DIR" || exit
    git checkout "$PACKAGE_VERSION" || exit
fi

# Install the package (setup.py builds bundled libjq + libonig from deps/jq-1.8.2.tar.gz)
if ! python3 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# Run tests
if ! python3 -m pytest tests/; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
fi