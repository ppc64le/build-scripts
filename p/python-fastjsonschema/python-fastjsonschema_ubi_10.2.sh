#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : python-fastjsonschema
# Version          : 2.22.2
# Source repo      : https://github.com/horejsek/python-fastjsonschema
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

PACKAGE_NAME=python-fastjsonschema
PACKAGE_VERSION=${1:-2.22.2}
PACKAGE_URL=https://github.com/horejsek/python-fastjsonschema
PACKAGE_DIR=python-fastjsonschema
CURRENT_DIR=$(pwd)

# ---------------------------------------------------------------------------
# System dependencies
# NOTE: Python packages MUST be listed first — the create_wheel_wrapper.sh
#       strips them and manages the Python install inside its own venv.
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make

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

# Handles both "v2.22.2" and "2.22.2" upstream tag styles
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
# ---------------------------------------------------------------------------
python3.14 -m pip install pytest

cd "$CURRENT_DIR/$PACKAGE_DIR"
if ! pytest . \
        --import-mode=importlib -v \
        -k "not (test_pattern_with_escape_no_warnings or benchmark)"; then
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
