#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyyaml
# Version       : 6.0.2rc1
# Source repo   : https://github.com/yaml/pyyaml
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pranith Rao <Pranith.Rao@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pyyaml
PACKAGE_VERSION=${1:-"6.0.2rc1"}
PACKAGE_URL=https://github.com/yaml/pyyaml.git

yum install -y git python3 python3-devel.ppc64le libyaml-devel gcc gcc-c++
yum remove -y python-chardet
pip3 install tox pytest cython
PATH=$PATH:/usr/local/bin/

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i 's/assert(False, "load() require Loader=...")/assert False, "load() requires Loader=..."/' tests/legacy_tests/test_dump_load.py

if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest ; then
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
