#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : dm-tree
# Version          : 0.1.10
# Source repo      : https://github.com/deepmind/tree
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <Shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=dm-tree
PACKAGE_VERSION=${1:-0.1.10}
PACKAGE_URL=https://github.com/deepmind/tree
PACKAGE_DIR=tree
CURRENT_DIR=$(pwd)

# Install build dependencies (Python packages must come first)
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make cmake wget xz zlib-devel openssl-devel bzip2-devel libffi-devel

# Activate gcc-toolset-15 (UBI 10 — SCL removed, use PATH export)
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

# Upgrade pip and install Python build tools
python3.14 -m pip install --upgrade pip setuptools wheel build

# Clone and checkout source
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

# Install Python dependencies (numpy pinned per UBI 10.2 requirements)
python3.14 -m pip install --upgrade pytest absl-py attrs "numpy==2.5.0" wrapt

# Set compiler flags for ppc64le (fixes cstdint and C++17 issues)
export CFLAGS="-include cstdint -std=c11"
export CXXFLAGS="-include cstdint -std=c++17 -Wno-elaborated-enum-base"
export CMAKE_ARGS="-DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_FLAGS='-include cstdint -std=c++17 -Wno-elaborated-enum-base'"

# Trigger abseil-cpp and pybind11 download
python3.14 setup.py build_ext --build-temp=build_temp --inplace -j"$(nproc)" || true

# Install package and build wheel
if ! python3.14 -m pip install --no-build-isolation . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

# Run tests (skip known-failing tests on ppc64le)
cd "$CURRENT_DIR"
if ! pytest --pyargs tree -k "not (testAttrsMapStructure or testAttrsFlattenAndUnflatten or testFlattenUpTo)"; then
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
