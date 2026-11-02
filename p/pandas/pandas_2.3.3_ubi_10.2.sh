#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pandas
# Version          : v2.3.3
# Source repo      : https://github.com/pandas-dev/pandas.git
# Tested on        : UBI:10.2
# Language         : Python, C, Cython
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sharath P J <sharath.pj@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=pandas
PACKAGE_VERSION=${1:-v2.3.3}
PACKAGE_URL=https://github.com/pandas-dev/pandas.git
PACKAGE_DIR=pandas
CURRENT_DIR=$(pwd)

# Install system dependencies
yum install -y python3.12 python3.12-devel python3.12-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    ninja-build make cmake openblas-devel

# Configure GCC Toolset 15
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
echo "Python version: $(python3.12 --version)"

# Install Python build tools
pip install --upgrade pip setuptools wheel build
pip install "meson-python>=0.13.1" "meson>=1.2.1" ninja "cython>=3.0" \
    "numpy>=2.0" "versioneer[toml]" "patchelf>=0.11.0"

# Clone repository
cd "$CURRENT_DIR"
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

# Checkout version
if git rev-parse "v${PACKAGE_VERSION#v}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION#v}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# Set version for versioneer — avoids version detection failures on a tag checkout
PLAIN_VERSION="${PACKAGE_VERSION#v}"
export SETUPTOOLS_SCM_PRETEND_VERSION="${PLAIN_VERSION}"

# Power9-compatible compiler flags
export CFLAGS="-mcpu=power9 -mtune=power9 -O2"
export CXXFLAGS="-mcpu=power9 -mtune=power9 -O2"

# Build wheel
if ! python3.12 -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Install built wheel and copy to CURRENT_DIR for wrapper script
pip install dist/pandas-*.whl
cp dist/*.whl "$CURRENT_DIR/"

# Run tests
cd "$CURRENT_DIR"
if ! python3.12 -c "
import pandas as pd
print('pandas version:', pd.__version__)
df = pd.DataFrame({'a': [1, 2, 3], 'b': [4, 5, 6]})
assert df.shape == (3, 2), f'unexpected shape: {df.shape}'
assert df['a'].sum() == 6, 'sum mismatch'
print('pandas smoke test passed')
"; then
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
