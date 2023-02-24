#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : sentry-python
# Version          : 1.12.1
# Source repo      : https://github.com/getsentry/sentry-python
# Tested on        : UBI 8.7
# Language         : python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=sentry-python
PACKAGE_VERSION=${1:-1.12.1}
PACKAGE_URL=https://github.com/getsentry/sentry-python

dnf install -y ncurses git python36 make python3-devel gcc gcc-c++

ln -s /usr/bin/python3 /usr/bin/python

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! pip3 install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pip3 install -r test-requirements.txt ; then
    echo "------------------$PACKAGE_NAME:test-requirements install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

pwd
ls -ltr /usr/local/lib/python3.6/site-packages/tox
ls -ltr /usr/local/bin/tox
# find / -name tox
# pip3 install pytest tox
#Build and test

#tox -e py3.6

tox -e py3.6
find / -name tox &>>/dev/null
if ! tox -e py3.6 ; then
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

