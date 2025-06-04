#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package       : bsdiff4
# Version       : 1.2.6
# Source repo   : https://github.com/ilanschnell/bsdiff4
# Tested on     : UBI 9.3
# Language      : c
# Travis-Check  : True
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

PACKAGE_NAME=bsdiff4
PACKAGE_VERSION=${1:-1.2.6}
PACKAGE_URL=https://github.com/ilanschnell/bsdiff4
PACKAGE_DIR=bsdiff4

# Install dependencies
yum install -y git wget gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran gcc-toolset-13-binutils gcc-toolset-13-binutils-devel python3 python3-pip python3-devel make automake autoconf libtool gdb rpm-build gettext

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Ensure pip is working for Python 3.12
python3 -m ensurepip --upgrade
python3 -m pip install --upgrade pip setuptools wheel
export PATH=$PATH:/usr/local/bin

# Install test dependencies
python3 -m pip install pytest "setuptools<68"

# Clone the package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install the package
if ! python3 -m pip install -e .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run tests
python3 -m pip install ".[test]"
if ! pytest; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Install_and_Test_Success"
    exit 0
fi
