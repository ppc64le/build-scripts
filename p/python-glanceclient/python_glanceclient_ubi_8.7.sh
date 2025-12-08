#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : python-glanceclient
# Version       : yoga-eom,4.5.0
# Source repo   : https://github.com/openstack/python-glanceclient
# Tested on     : UBI 8.7
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=python-glanceclient
PACKAGE_VERSION=${1:-yoga-eom}
PACKAGE_URL=https://github.com/openstack/python-glanceclient

yum install -y git wget gcc gcc-c++ python39 python39-pip python39-devel python39-psycopg2 libxslt libxslt-devel make libpq libpq-devel openssl-devel cmake xz libaio 

#Install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
source ~/.cargo/env

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install "cython<3.0.0" wheel tox && pip3 install --no-build-isolation pyyaml==6.0

if ! python3 -m pip install -r requirements.txt ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
python3 -m pip install -r test-requirements.txt
if ! tox -e py39 ; then
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
