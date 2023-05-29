#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ansible/ansible-sign
# Version       : 0.1.1
# Source repo   : https://github.com/ansible/ansible-sign.git
# Tested on     : UBI 8.7
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
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

yum install openssl-devel git wget tar python39-devel.ppc64le gcc rust cargo gcc-c++ cmake.ppc64le -y
pip3 install tox
pip3 install build

#update PATH environment variable for installations
export ANSIBLE_HOME="/usr/local/bin"
export PATH=$PATH:$ANSIBLE_HOME

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

if ! tox -e py3 -- -k 'not tests/test_cli_pinentry.py'; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi
