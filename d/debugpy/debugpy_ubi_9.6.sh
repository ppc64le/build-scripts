#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : debugpy
# Version       : v1.8.20
# Source repo   : https://github.com/microsoft/debugpy.git
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: MIT License
# Maintainer    : Vrusha Naik <Vrusha.Naik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=debugpy
PACKAGE_VERSION=${1:-v1.8.20}
PACKAGE_URL=https://github.com/microsoft/debugpy.git
PACKAGE_DIR=debugpy

# Install dependencies
yum install -y git python3 python3-devel gcc gcc-c++ make

pip3 install --upgrade pip setuptools wheel

export PATH=$PATH:/usr/local/bin/

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Clone the package
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
    exit 1
fi
cd "$PACKAGE_DIR" || exit
git checkout "$PACKAGE_VERSION"

# Build and install the attach_ppc64le.so native library required for attach-to-pid tests.
# The upstream compile_linux.sh only covers x86/amd64; ppc64le must be compiled manually.
ATTACH_DIR="src/debugpy/_vendored/pydevd/pydevd_attach_to_process"
g++ -std=c++11 -shared -fPIC -O2 -D_FORTIFY_SOURCE=2 -nostartfiles \
    -fstack-protector-strong \
    "${ATTACH_DIR}/linux_and_mac/attach.cpp" \
    -o "${ATTACH_DIR}/attach_ppc64le.so"

# Install the package
if ! python3 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# Install test dependencies
pip3 install pytest pytest-xdist pytest-timeout pytest-retry pytest-cov psutil untangle \
    importlib_metadata gevent flask django requests numpy

# Run tests — skip attach-to-pid tests as they require ptrace privileges
# not available in container environments.
if ! python3 -Xfrozen_modules=off -m pytest tests/ \
    --ignore=tests/tests/test_attach_to_pid.py \
    -p no:warnings; then
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
