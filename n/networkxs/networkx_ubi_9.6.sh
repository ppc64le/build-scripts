#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : murmurhash
# Version          : networkx-3.6.1
# Source repo      : https://github.com/networkx/networkx.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -ex

# Variables
PACKAGE_NAME=networkx
PACKAGE_VERSION=${1:-"networkx-3.6.1"}
PACKAGE_URL=https://github.com/networkx/networkx.git
PACKAGE_DIR=networkx

# Install dependencies
yum install -y git gcc gcc-c++ make python3.11 python3.11-devel python3.11-pip python3.11-setuptools

# Upgrade pip and install required tools
python3.11 -m pip install --upgrade pip setuptools wheel

# Install test dependencies
python3.11 -m pip install pytest pytest-cov pytest-xdist

export PATH=$PATH:/usr/local/bin/

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Install package
if ! python3.11 -m pip install -v .; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run tests
if ! python3.11 -m pytest -v; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi