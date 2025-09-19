#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : Stripe-python
# Version          : v12.2.0
# Source repo      : https://github.com/stripe/stripe-python.git
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
set -ex

#variables
PACKAGE_NAME=stripe-python
PACKAGE_VERSION=${1:-v12.2.0}
PACKAGE_URL=https://github.com/stripe/stripe-python.git
PACKAGE_DIR=stripe-python
CURRENT_DIR=$(pwd)

#install dependencies
yum install -y git gcc-toolset-13 make wget openssl-devel bzip2-devel libffi-devel zlib-devel python3 python-devel python3-pip

#export gcc-toolset path
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd deps
pip install pytest tox pip wheel
pip install -r build-requirements.txt
pip install -r test-requirements.txt
cd $CURRENT_DIR
cd $PACKAGE_NAME

#install
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Skipping tests because it requires stripe-mock server to be running
if ! pytest --nomock -k "not test_invoice.py and not test_invoice_line_item.py"; then
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
