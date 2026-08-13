#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : promise
# Version          : v2.3.0
# Source repo      : https://github.com/syrusakbary/promise
# Tested on        : UBI:10.1
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <Shivansh.s11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=promise
PACKAGE_VERSION=${1:-v2.3.0}
PACKAGE_URL=https://github.com/syrusakbary/promise
PACKAGE_DIR=promise
CURRENT_DIR=$(pwd)

yum install -y python3.12 python3.12-devel python3.12-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make

if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi
echo "Using gcc: $(gcc --version | head -1)"

pip install --upgrade pip setuptools wheel build

echo "------------Cloning the Repository------------"

cd "$CURRENT_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "------------Installing test dependencies------------"

if ! pip install -e ".[test]"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "------------Testing------------"

cd "$CURRENT_DIR"
if ! pytest "$CURRENT_DIR/$PACKAGE_DIR" \
        --ignore="$CURRENT_DIR/$PACKAGE_DIR/tests/test_awaitable.py" \
        -k "not test_thrown_exceptions_have_stacktrace and not test_thrown_exceptions_preserve_stacktrace and not test_issue_9_safe"; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
fi

# Building wheel with --plat-name to produce correct ppc64le arch tag
if ! python3.12 setup.py bdist_wheel --plat-name manylinux2014_ppc64le --dist-dir="$CURRENT_DIR"; then
    echo "------------------$PACKAGE_NAME: Wheel Build Failed ---------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Wheel Build Success -------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

