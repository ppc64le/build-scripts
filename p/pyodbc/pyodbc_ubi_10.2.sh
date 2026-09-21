#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyodbc
# Version          : 5.3.0
# Source repo      : https://github.com/mkleehammer/pyodbc
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

PACKAGE_NAME=pyodbc
PACKAGE_VERSION=${1:-5.3.0}
PACKAGE_URL=https://github.com/mkleehammer/pyodbc
PACKAGE_DIR=pyodbc
CURRENT_DIR=$(pwd)

# ---------------------------------------------------------------------------
# System dependencies
# NOTE: Python packages MUST be listed first — the create_wheel_wrapper.sh
#       strips them and manages the Python install inside its own venv.
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make wget unixODBC-devel openssl-devel

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15
# UBI 10 removed SCL — the `source enable` script does NOT exist.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Python build tools  (always via pip, never via yum)
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build

# ---------------------------------------------------------------------------
# Clone & checkout
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Build & install
# ---------------------------------------------------------------------------
if ! python3.14 -m pip install --no-build-isolation .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Produce wheel artefact for create_wheel_wrapper.sh
python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

# ---------------------------------------------------------------------------
# Test
# No need to run full tests — testing requires a running ODBC-compatible
# database and connection string. Basic import smoke test performed instead.
# ---------------------------------------------------------------------------
if ! python3.14 -c "import pyodbc; print('pyodbc import OK')"; then
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
