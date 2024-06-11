#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : odoo
# Version       : 17.0
# Source repo   : https://github.com/odoo/odoo
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
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
PACKAGE_NAME=odoo
PACKAGE_VERSION=${1:-17.0}
PACKAGE_URL=https://github.com/odoo/odoo


yum install -y wget git yum-utils openldap-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libjpeg-devel openssl openssl-devel postgresql-devel gcc gcc-c++ libicu lz4 make bzip2-devel zlib-devel
yum install python3.11 python3.11-pip python3.11-devel -y

#install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

python3.11 -m venv odoo-venv
. ./odoo-venv/bin/activate

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3.11 -m pip install pip wheel tox

if ! python3.11 -m pip install -r requirements.txt; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! tox -e py3.11; then
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
