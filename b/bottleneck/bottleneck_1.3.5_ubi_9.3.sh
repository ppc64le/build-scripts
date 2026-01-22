#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : bottleneck
# Version       : v1.6.0
# Source repo   : https://github.com/pydata/bottleneck.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=bottleneck
PACKAGE_VERSION=${1:-v1.6.0}
PACKAGE_URL=https://github.com/pydata/bottleneck.git

# Install dependencies and tools.
yum install -y wget gcc gcc-c++ gcc-gfortran git make  python3.12 python3.12-pip python3.12-devel  openssl-devel

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install
if ! (python3.12 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.12 -m pip install versioneer oldest-supported-numpy
python3.12 -m pip install chardet --upgrade
python3.12 -m pip install requests --upgrade
python3.12 -m pip install tox
python3.12 -m pip install pytest hypothesis

# test
cd ..
if ! python3.12 -c "import bottleneck; bottleneck.test()"; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
