#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : sentry-python
# Version       : 2.29.1
# Source repo   : https://github.com/getsentry/sentry-python
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

#variables
PACKAGE_NAME=sentry-python
PACKAGE_VERSION=${1:-2.29.1}
PACKAGE_URL=https://github.com/getsentry/sentry-python
PACKAGE_DIR=sentry-python
CURRENT_DIR=$(pwd)

yum install -y ncurses wget git python3.12 python3.12-devel python3.12-pip make gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

#cloning the repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3.12 install --upgrade requests tox
pip3.12 install -r requirements-testing.txt

#Build package
if ! pip3.12 install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

pip3.12 install -r scripts/populate_tox/requirements.txt
pip3.12 install -r scripts/split_tox_gh_actions/requirements.txt

#Test package
if ! tox -e py3 ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
