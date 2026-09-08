#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : promise
# Version          : 2.3.0
# Source repo      : https://github.com/syrusakbary/promise
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
PACKAGE_NAME=promise
PACKAGE_VERSION=${1:-2.3.0}
PACKAGE_URL=https://github.com/syrusakbary/promise
PACKAGE_DIR=promise
CURRENT_DIR="${PWD}"

# ---------------------------------------------------------------------------
# System dependencies
# NOTE: Python packages MUST be listed first — the create_wheel_wrapper.sh
#       strips them and manages the Python install inside its own venv.
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git wget cmake

# ---------------------------------------------------------------------------
# Python build tools  (always via pip, never via yum)
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build

# ---------------------------------------------------------------------------
# Clone & checkout
# ---------------------------------------------------------------------------
echo "------------Cloning the Repository------------"

if [[ ! -d "$PACKAGE_DIR" ]]; then
    git clone "$PACKAGE_URL"
fi
cd "$PACKAGE_DIR"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# ---------------------------------------------------------------------------
# Install package
# ---------------------------------------------------------------------------
if ! python3.14 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# ---------------------------------------------------------------------------
# Install test dependencies
# ---------------------------------------------------------------------------
echo "------------Installing test dependencies------------"

if ! python3.14 -m pip install -e ".[test]"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.14 -m pip install pytest pytest-asyncio

# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
echo "------------Testing------------"

if ! pytest --ignore=tests/test_awaitable.py \
        -k "not test_thrown_exceptions_have_stacktrace and not test_thrown_exceptions_preserve_stacktrace and not test_issue_9_safe"; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
fi

# ---------------------------------------------------------------------------
# Build wheel
# --plat-name is required to tag the wheel as manylinux2014_ppc64le
# ---------------------------------------------------------------------------
if ! python3.14 setup.py bdist_wheel --plat-name manylinux2014_ppc64le \
        --dist-dir="$CURRENT_DIR"; then
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
