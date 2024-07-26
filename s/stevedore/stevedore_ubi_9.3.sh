#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : stevedore
# Version       : zed-eom
# Source repo   : https://github.com/openstack/stevedore
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
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

set -e
PACKAGE_NAME=stevedore
PACKAGE_VERSION=${1:-'zed-eom'}
PACKAGE_URL=https://github.com/openstack/stevedore

yum install -y git python3 python3-devel.ppc64le
yum remove -y python-chardet
pip3 install tox setuptools pytest
PATH=$PATH:/usr/local/bin/

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

REQUIREMENTS_PRESENT=(`find . -print | grep -i requirements.txt`)

for i in "${REQUIREMENTS_PRESENT[@]}"; do
        echo "Installing using pip from file:"
        echo $i
        pip3  install -r $i
done

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
