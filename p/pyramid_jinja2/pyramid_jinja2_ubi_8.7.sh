#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyramid_jinja2
# Version          : 2.10.1
# Source repo      : https://github.com/Pylons/pyramid_jinja2.git
# Tested on        : UBI 8.7
# Language         : Python
# Travis-Check     : True
# Script License   : GNU General Public License v3.0
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

PACKAGE_NAME=pyramid_jinja2
PACKAGE_VERSION=${1:-"2.10.1"}
PACKAGE_URL=https://github.com/Pylons/pyramid_jinja2.git

yum install -y git gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget
yum install -y python3 python3-devel python3-setuptools

python3 -m ensurepip --upgrade
python3 -m pip install build tox webtest --ignore-installed
PATH=$PATH:/usr/local/bin/

python3 -m pip install --upgrade jinja2==3.0.3

# Clone and build source code.
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3 setup.py test ; then
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
