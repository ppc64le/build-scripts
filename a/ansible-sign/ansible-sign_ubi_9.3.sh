#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ansible/ansible-sign
# Version       : 0.1.1
# Source repo   : https://github.com/ansible/ansible-sign.git
# Tested on     : UBI 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Gupta <Shubham.Gupta43@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ansible-sign
PACKAGE_VERSION=${1:-0.1.1}
PACKAGE_URL=https://github.com/ansible/ansible-sign.git

yum install openssl-devel git wget tar  gcc rust cargo gcc-c++ cmake.ppc64le pip -y
pip install tox
pip install build

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! python3 -m build; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

tox -- \
    --ignore=tests/test_cli_pinentry.py

if [ $? -eq 0 ]; then
    echo "------------------$PACKAGE_NAME:Both_build_and_test_pass---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0

else
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2

fi

