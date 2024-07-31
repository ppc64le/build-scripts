#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : BTrees
# Version          : 6.0
# Source repo      : https://github.com/zopefoundation/BTrees
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=BTrees
PACKAGE_VERSION=${1:-6.0}
PACKAGE_URL=https://github.com/zopefoundation/BTrees.git

yum install -y --allowerasing git gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget libffi-devel libpq-devel

export PKG_CONFIG_PATH="/usr/bin/pg_config"

yum install -y python3 python3-devel python3-setuptools
python3 -m ensurepip --upgrade
#pip3 install tox
python3 -m pip install tox --ignore-installed
PATH=$PATH:/usr/local/bin/

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

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
