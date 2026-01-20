#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ipykernel
# Version       : v6.29.4
# Source repo   : https://github.com/ipython/ipykernel
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -ex

PACKAGE_NAME=ipykernel
PACKAGE_VERSION=${1:-v6.29.4}
PACKAGE_URL=https://github.com/ipython/ipykernel
PACKAGE_DIR=ipykernel

# Install dependencies
yum install -y cmake make git python3 python3-devel python3-pip python3-pytest gcc-toolset-13

#export path for gcc-13
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

python3 -m pip install trio pytest flaky jupyter-client hatchling

# Clone package repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install
if ! python3 -m pip install -e ".[test]"; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi

# Test
if ! pytest -vv -s -k "not test_message_spec and not test_ipython_start_kernel_userns and not test_asyncio_interrupt"; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi
