#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : tornado
# Version          : v6.3.3
# Source repo      : https://github.com/tornadoweb/tornado
# Tested on	: UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <ich@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=tornado
PACKAGE_VERSION=${1:-v6.4.2}
PACKAGE_URL=https://github.com/tornadoweb/tornado
PACKAGE_DIR=tornado
CURRENT_DIR="${PWD}"

# Install dependencies
yum install python3 python3-devel python3-pip git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran libcurl-devel openssl-devel -y

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install build tox wheel "pycares<5" "twisted<24.7" pycurl

python3 setup.py sdist

cd dist/
VERSION_NUMBER="${PACKAGE_VERSION#v}"
tar -zxvf tornado-"$VERSION_NUMBER".tar.gz
cd tornado-"$VERSION_NUMBER"

#install
if ! pip3 install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd $CURRENT_DIR/tornado

# Run tests
if !(python3 -m tox -e py39); then
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
