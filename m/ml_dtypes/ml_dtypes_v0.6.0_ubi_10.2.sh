#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ml-dtypes
# Version          : v0.6.0
# Source repo      : https://github.com/jax-ml/ml_dtypes
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <shivansh.sharma1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=ml-dtypes
PACKAGE_VERSION=${1:-v0.6.0}
PACKAGE_URL=https://github.com/jax-ml/ml_dtypes
PACKAGE_DIR=ml_dtypes
CURRENT_DIR=$(pwd)

# ---------------------------------------------------------------------------
# System dependencies
# NOTE: Python packages MUST be listed first — the create_wheel_wrapper.sh
#       strips them and manages the Python install inside its own venv.
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake make

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
# Python build tools
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build pytest absl-py
python3.14 -m pip install "numpy==2.5.0" pybind11 scikit-build-core ninja

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

git submodule sync --recursive
git submodule update --init --recursive

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
if ! python3.14 -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
cp dist/*.whl "$CURRENT_DIR/"

# ---------------------------------------------------------------------------
# Install built wheel and run smoke test
# ---------------------------------------------------------------------------
python3.14 -m pip install "$CURRENT_DIR"/ml_dtypes*.whl

if ! pytest; then
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
