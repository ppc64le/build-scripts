#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : markupsafe
# Version       : 2.1.1
# Source repo   : https://github.com/pallets/markupsafe
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Simran Sirsat <Simran.Sirsat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=markupsafe
PACKAGE_VERSION=${1:-2.1.1}
PACKAGE_URL=https://github.com/pallets/markupsafe

yum install -y git python3 python3-pip python3-devel.ppc64le gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel xz cmake zlib-devel openblas-devel

PATH=$PATH:/usr/local/bin/

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Installing all the requirements
pip install -r requirements/tests.txt
pip install -r requirements/typing.txt
pip install -r requirements/docs.txt
pip install pytest tox==3.24.5
pip install wheel==0.37.1
pip install virtualenv==20.13.1

if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! (tox -e py3) ; then
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
