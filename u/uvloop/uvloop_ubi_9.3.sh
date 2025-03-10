#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : uvloop
# Version       : v0.20.0
# Source repo   : https://github.com/MagicStack/uvloop.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=uvloop
PACKAGE_VERSION=${1:-"v0.20.0"}
PACKAGE_URL=https://github.com/MagicStack/uvloop.git
PYTHON_VERSION=${PYTHON_VERSION:-"3.11"}

yum install -y git libffi-devel autoconf automake libtool gettext gcc-toolset-13 python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-setuptools

source /opt/rh/gcc-toolset-13/enable
python${PYTHON_VERSION} -m pip install pytest psutil

if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL
  cd $PACKAGE_NAME
else
  cd $PACKAGE_SOURCE_DIR
fi

git checkout $PACKAGE_VERSION

git submodule update --init --recursive

# Build and install the package
if ! python${PYTHON_VERSION} -m pip install -v -e .[dev]; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases
if ! python${PYTHON_VERSION} -m pytest tests/test_base.py tests/test_fs_event.py tests/test_process.py tests/test_runner.py tests/test_libuv_api.py tests/test_sockets.py tests/test_signals.py tests/test_dealloc.py ; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
