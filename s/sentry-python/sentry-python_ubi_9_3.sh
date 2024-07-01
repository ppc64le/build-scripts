#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : sentry-python
# Version       : 2.7.1
# Source repo   : https://github.com/getsentry/sentry-python
# Tested on     : UBI: 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
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
PACKAGE_VERSION=${1:-2.7.1}
PACKAGE_URL=https://github.com/getsentry/sentry-python
HOME_DIR=${PWD}

sudo dnf install -y ncurses wget git python3 python3-devel make gcc gcc-c++ 

#creating virtual environment
pip3 install virtualenv
export PATH=$HOME_DIR/.local/bin:$PATH
virtualenv --version
virtualenv myenv
virtualenv -p /usr/bin/python3 myenv
source myenv/bin/activate


sudo ln -s /usr/bin/python3 /usr/bin/python

#cloning the repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
pip install --upgrade requests tox
pip install pytest==6.2.5
pip install -r requirements-testing.txt

#Build package
if ! pip3 install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Test package
if ! pytest ; then
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