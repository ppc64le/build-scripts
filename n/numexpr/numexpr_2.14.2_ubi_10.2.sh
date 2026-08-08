#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : numexpr
# Version          : v2.14.2
# Source repo      : https://github.com/pydata/numexpr.git
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <Shivansh.S1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=numexpr
PACKAGE_VERSION=${1:-v2.14.2}
PACKAGE_URL=https://github.com/pydata/numexpr.git
PACKAGE_DIR=numexpr
CURRENT_DIR=$(pwd)

# Python packages MUST be listed first — create_wheel_wrapper.sh strips them
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make cmake openblas-devel

# Activate GCC Toolset 15 (SCL removed in UBI 10)
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

python3.14 -m pip install --upgrade pip setuptools wheel build

# Clone and checkout
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

# Fix pyproject.toml for PEP 639 / setuptools compatibility
sed -i 's/^license = "MIT"/license = {text = "MIT"}/' pyproject.toml
sed -i '/^license-files/d' pyproject.toml

# Install pinned numpy (UBI 10.2 requirement) and build
python3.14 -m pip install "numpy==2.5.0"

if ! python3.14 -m pip install --no-build-isolation .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Produce the wheel artefact for wheel_build=true
python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

# Test
cd "$CURRENT_DIR"
python3.14 -m pip install pytest
if ! python3.14 -m pytest "$CURRENT_DIR/$PACKAGE_DIR/numexpr/tests/"; then
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
