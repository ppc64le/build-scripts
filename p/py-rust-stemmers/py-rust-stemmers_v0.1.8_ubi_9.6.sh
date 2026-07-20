#!/bin/bash
# -----------------------------------------------------------------------------
# Package       : py-rust-stemmers
# Version       : 0.1.8
# Source repo   : https://github.com/qdrant/py-rust-stemmers
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ethan Choe <ethanchoe@ibm.com>
# -----------------------------------------------------------------------------
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_DIR="py-rust-stemmers"
PACKAGE_NAME="py_rust_stemmers"
PACKAGE_VERSION=${1:-v0.1.8}
PACKAGE_URL="https://github.com/qdrant/py-rust-stemmers.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"

# Install build frontend
python3.12 -m pip install build

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "${PACKAGE_DIR}"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

# Build wheel
python3.12 -m build --wheel --outdir "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

cd "${SOURCE_ROOT}"

# Install wheel
echo "=== Installing Wheel ==="
python3.12 -m pip install "$WHEEL"

# Test
echo "=== Running Tests ==="

# 1. Version check
python3.12 -c "import importlib.metadata; print('version:', importlib.metadata.version('py-rust-stemmers'))"

# 2. Basic stemming smoke test
python3.12 - <<'EOF'
from py_rust_stemmers import SnowballStemmer

stemmer = SnowballStemmer("english")
result = stemmer.stem_word("running")
assert result == "run", f"Expected 'run', got '{result}'"
print("english stemmer: OK")

stemmer_de = SnowballStemmer("german")
result_de = stemmer_de.stem_word("laufenden")
assert isinstance(result_de, str) and len(result_de) > 0, f"Unexpected result: {result_de}"
print("german stemmer: OK")
EOF

# 3. Run upstream test suite
echo "=== Running Upstream Tests ==="
# Run upstream test suite
python3.12 -m pip install pytest
cd "${SOURCE_ROOT}/${PACKAGE_DIR}"
python3.12 -m pytest

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"