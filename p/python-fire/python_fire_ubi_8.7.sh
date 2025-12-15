#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : python-fire
# Version          : v0.5.0
# Source repo      : https://github.com/google/python-fire.git
# Tested on        : UBI 8.7
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Mohit Pawar <mohit.pawar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=python-fire
PACKAGE_VERSION=${1:-v0.5.0}
PACKAGE_URL=https://github.com/google/python-fire.git

yum install -y git gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget

yum install -y python39 python39-devel

python3 -m ensurepip --upgrade
python3 -m pip install tox --ignore-installed
PATH=$PATH:/usr/local/bin/

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 -m pip install pytest mock hypothesis

if ! python3 setup.py build ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! tox -e py3 ; then
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
