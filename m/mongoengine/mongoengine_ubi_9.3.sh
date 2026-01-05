#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package       : mongoengine
# Version       : v0.29.1
# Source repo   : https://github.com/MongoEngine/mongoengine
# Tested on     : UBI 9.3
# Language      : c
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=mongoengine
PACKAGE_VERSION=${1:-v0.29.1}
PACKAGE_URL=https://github.com/MongoEngine/mongoengine
PACKAGE_DIR=mongoengine

yum install -y yum-utils python3 python3-pip python3-devel git gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ zlib-devel libjpeg-turbo libjpeg-turbo-devel gcc gcc-c++ libtiff freetype freetype-devel libwebp openjpeg2 wget
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH


git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION 

pip3 install tox 'pymongo==3.11.4' blinker
python3 -m pip install -r docs/requirements.txt

if ! pip3 install . ;  then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! tox -e $(echo py3.9-mg311 | tr -d . | sed -e 's/pypypy/pypy/') -- -k test_ci_placeholder ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
