#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : python-zeroconf
# Version       : 0.150.0
# Source repo   : https://github.com/python-zeroconf/python-zeroconf
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Rosman Carino <rcarino@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=python-zeroconf
PACKAGE_VERSION=${1:-0.150.0}
PACKAGE_URL=https://github.com/python-zeroconf/python-zeroconf
PACKAGE_DIR=python-zeroconf

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Install system dependencies
yum install -y git python3 python3-devel gcc-toolset-13 make wget sudo

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Install Python build and test dependencies
pip3 install \
    "setuptools>=77.0" \
    "Cython>=3.0.8" \
    "poetry-core>=2.1.0" \
    ifaddr \
    pytest \
    pytest-asyncio \
    pytest-timeout \
    pytest-cov \
    pytest-codspeed

# Clone the repo
if [ -d "$PACKAGE_DIR" ]; then
    cd "$PACKAGE_DIR" || exit
else
    if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
        exit 1
    fi
    cd "$PACKAGE_DIR" || exit
    git checkout "$PACKAGE_VERSION" || exit
fi

# Install the package (builds Cython extensions via build_ext.py)
if ! python3 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# Run tests
# SKIP_IPV6=1: the build container can bind ::1 but has no IPv6 multicast routing
# (ff02::fb is unreachable), so the IPv6 integration test is skipped via its own
# built-in guard: @unittest.skipIf(os.environ.get("SKIP_IPV6"), ...)
if ! SKIP_IPV6=1 python3 -m pytest tests/; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
fi