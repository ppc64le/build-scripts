#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : lz4
# Version       : v4.4.5
# Source repo   : https://github.com/python-lz4/python-lz4
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_DIR="python-lz4"
PACKAGE_NAME="lz4"
PACKAGE_VERSION=${1:-v4.4.5}
PACKAGE_URL="https://github.com/python-lz4/python-lz4.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"

# Source-built Pythons install libpythonX.Y.so.1.0 to /usr/local/lib but the
# linker cache may not include that path yet.  Register it and also set
# LD_LIBRARY_PATH as a fallback for environments where ldconfig has no effect.
ldconfig
export LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Install build frontend + build-time deps
python3.12 -m pip install "build" "setuptools>=45" "wheel" "setuptools_scm[toml]>=6.2" "pkgconfig"

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "${PACKAGE_DIR}"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

# setuptools_scm derives the version from git tags.
# Export the version explicitly so shallow/detached checkouts work correctly.
SEMVER="${PACKAGE_VERSION#v}"
export SETUPTOOLS_SCM_PRETEND_VERSION="${SEMVER}"

# Build wheel (all lz4 C sources are bundled in lz4libs/ — no system liblz4 needed)
python3.12 -m build --wheel --outdir "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

cd "${SOURCE_ROOT}"

# Install wheel + test dependencies
echo "=== Installing Wheel ==="
python3.12 -m pip install "${WHEEL}"
python3.12 -m pip install pytest pytest-timeout psutil

# Run tests
echo "=== Running Tests ==="

# 1. Version check
python3.12 -c "import importlib.metadata; print('lz4 version:', importlib.metadata.version('lz4'))"

# 2. Upstream unit tests.
#    - block/ and frame/ tests are pure compression round-trips; no external services.
#    - stream/ tests are skipped (only built when PYLZ4_EXPERIMENTAL=True).
#    Run from SOURCE_ROOT so Python uses the installed wheel, not the source tree
#    (setup.cfg sets inplace=1 which leaves no compiled extensions in the source lz4/).
python3.12 -m pytest \
    "${PACKAGE_DIR}/tests/block/" \
    "${PACKAGE_DIR}/tests/frame/" \
    -v \
    --timeout=60 \
    -x

TEST_EXIT=$?
if [ "$TEST_EXIT" -ne 0 ]; then
    echo "ERROR: Tests failed (exit $TEST_EXIT)"
    exit "$TEST_EXIT"
fi

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"