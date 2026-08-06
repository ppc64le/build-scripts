#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : onigurumacffi
# Version       : v1.5.0
# Source repo   : https://github.com/asottile/onigurumacffi
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

set -ex

# Variables
PACKAGE_NAME=onigurumacffi
PACKAGE_VERSION=${1:-v1.5.0}
PACKAGE_URL=https://github.com/asottile/onigurumacffi
PACKAGE_DIR=onigurumacffi

# Oniguruma C library version (required by the CFFI build; no devel package on UBI 9)
ONIGURUMA_VERSION=v6.9.10
ONIGURUMA_URL=https://github.com/kkos/oniguruma

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Install system dependencies
# oniguruma-devel is not available on UBI 9; build oniguruma from source below
# python3.12 is the minimum version satisfying onigurumacffi's python_requires>=3.10
yum install -y git python3.12 python3.12-devel python3.12-pip gcc-toolset-13 make wget sudo autoconf automake libtool

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Install Python build dependencies
python3.12 -m pip install cffi setuptools wheel pytest

# Build and install oniguruma from source (provides libonig + headers for CFFI compile)
# /usr/local/lib is not in the default ld search path on UBI 9; register it explicitly
# so libonig.so.5 is found at runtime (each Python-version container is independent)
echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
if ! ldconfig -p | grep -q libonig; then
    ONIGURUMA_CLONE=$(mktemp -d)
    git init "$ONIGURUMA_CLONE"
    cd "$ONIGURUMA_CLONE"
    git remote add origin "$ONIGURUMA_URL"
    git -c protocol.version=2 fetch --depth=1 origin "$ONIGURUMA_VERSION"
    git checkout FETCH_HEAD
    ./autogen.sh
    ./configure
    make -j"$(nproc)"
    make install
    ldconfig
    cd -
    rm -rf "$ONIGURUMA_CLONE"
fi
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Clone the repo (use pre-cloned dir if present)
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

# Install the package (builds the CFFI extension against libonig)
if ! python3.12 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# Run tests
if ! python3.12 -m pytest tests/; then
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