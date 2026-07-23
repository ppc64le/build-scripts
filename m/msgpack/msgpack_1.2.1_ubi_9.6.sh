#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : msgpack
# Version       : v1.2.1
# Source repo   : https://github.com/msgpack/msgpack-python
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
REPO_DIR="msgpack-python"
PACKAGE_NAME="msgpack"
PACKAGE_VERSION=${1:-v1.2.1}
PACKAGE_URL="https://github.com/msgpack/msgpack-python.git"
SOURCE_ROOT="$(pwd)"

# PACKAGE_DIR must point to the actual Python package (contains pyproject.toml)
PACKAGE_DIR="${REPO_DIR}"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
# gcc-c++ is required to compile the C extension (_cmsgpack)
dnf install -y gcc gcc-c++ git python3.13 python3.13-devel python3.13-pip

# Install build frontend and Cython (needed to regenerate the C extension source)
python3.13 -m pip install --upgrade pip build setuptools "cython>=3.2.5"

# Clone and checkout
rm -rf "$REPO_DIR"
git clone "$PACKAGE_URL" "$REPO_DIR"
cd "${REPO_DIR}"
git checkout "$PACKAGE_VERSION"

DIST_DIR="${SOURCE_ROOT}/dist"
mkdir -p "$DIST_DIR"

# Generate _cmsgpack.c from the Cython source before building the wheel.
# The .c file is not committed to the repo and must be produced at build time.
echo "=== Generating C extension source via Cython ==="
python3.13 -m cython msgpack/_cmsgpack.pyx -o msgpack/_cmsgpack.c

# Build the wheel (setup.py compiles the generated _cmsgpack.c into a native extension)
echo "=== Building msgpack ==="
python3.13 -m build --wheel --outdir "$DIST_DIR" .

WHEEL=$(find "$DIST_DIR" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: msgpack wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

cd "${SOURCE_ROOT}"

# Install the wheel
echo "=== Installing msgpack ==="
python3.13 -m pip install "$WHEEL"

# Install test dependencies
python3.13 -m pip install pytest

# Test
echo "=== Running Tests ==="

# 1. Version check
python3.13 -c "import importlib.metadata; print('version:', importlib.metadata.version('msgpack'))"

# 2. Basic import and round-trip smoke test
python3.13 - <<'EOF'
import msgpack
print("msgpack import: OK")

# Verify the C extension is loaded (not pure-Python fallback)
from msgpack import _cmsgpack
print("msgpack C extension loaded: OK")

# Round-trip pack/unpack
data = {"key": [1, 2, 3], "hello": "world", "flag": True}
packed = msgpack.packb(data, use_bin_type=True)
unpacked = msgpack.unpackb(packed, raw=False)
assert unpacked == data, f"Round-trip mismatch: {unpacked!r}"
print("msgpack pack/unpack round-trip: OK")
EOF

# 3. Run the upstream test suite
echo "=== Running upstream pytest suite ==="
python3.13 -m pytest "${REPO_DIR}/test" -v --tb=short

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"