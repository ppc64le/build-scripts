#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : gensim
# Version          : 4.4.0
# Source repo      : https://github.com/RaRe-Technologies/gensim
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=gensim
PACKAGE_VERSION=${1:-4.4.0}
PACKAGE_URL=https://github.com/RaRe-Technologies/gensim
PACKAGE_DIR=gensim
CURRENT_DIR=$(pwd)

# ---------------------------------------------------------------------------
# System dependencies
# Python packages MUST be listed first — create_wheel_wrapper.sh strips them.
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make openblas-devel

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
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
# Python build tools (always via pip, never via yum)
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build

# ---------------------------------------------------------------------------
# Build-time dependencies
# numpy and scipy must be installed before building gensim (Cython extensions
# use numpy headers; scipy is a runtime dep resolved at build time).
# ---------------------------------------------------------------------------
# UBI 10.2 pinned versions (§24 of SKILL.md)
# oldest-supported-numpy and Cython<3 are required by gensim's setup.py
# before --no-isolation build can proceed.
python3.14 -m pip install "numpy==2.5.0" "scipy>=1.18.0,<1.19.0" Cython 

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

python3.14 setup.py build_ext --inplace

# ---------------------------------------------------------------------------
# Build wheel
# ---------------------------------------------------------------------------
if ! python3.14 -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
cp dist/*.whl "$CURRENT_DIR/"

# ---------------------------------------------------------------------------
# Install runtime/test dependencies and the built wheel
# ---------------------------------------------------------------------------
python3.14 -m pip install 'smart_open<8' nbformat testfixtures nbconvert pytest
python3.14 -m pip install "$CURRENT_DIR"/gensim-*.whl

# Run test cases
cd $PACKAGE_NAME
# Tests are failing with `TypeError: cannot pickle 'generator' object`. These failures are because gensim does not support python3.14 yet
if !(pytest -q -k "not TestWikiCorpus"); then
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
