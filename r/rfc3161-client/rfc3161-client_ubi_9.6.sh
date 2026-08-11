#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : rfc3161-client
# Version          : v1.0.6
# Source repo      : https://github.com/trailofbits/rfc3161-client.git
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
set -ex

# Variables
PACKAGE_NAME=rfc3161-client
PACKAGE_VERSION=${1:-"v1.0.6"}
PACKAGE_URL=https://github.com/trailofbits/rfc3161-client.git
PACKAGE_DIR=rfc3161-client

# Install dependencies
yum install -y git gcc gcc-c++ make python3.11 python3.11-devel python3.11-pip python3.11-setuptools openssl-devel perl perl-core rust cargo

python3.11 -m pip install --upgrade pip
python3.11 -m pip install pytest maturin pretend

export PATH=$PATH:/usr/local/bin/

# Force system OpenSSL
export OPENSSL_DIR=/usr
export OPENSSL_LIB_DIR=/usr/lib64
export OPENSSL_INCLUDE_DIR=/usr/include
export OPENSSL_NO_VENDOR=1

# Clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

git submodule update --init --recursive

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
