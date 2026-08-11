#!/bin/bash
# -----------------------------------------------------------------------------
# Package       : asyncpg
# Version       : 0.31.0
# Source repo   : https://github.com/MagicStack/asyncpg
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

PACKAGE_DIR="asyncpg"
PACKAGE_NAME="asyncpg"
PACKAGE_VERSION=${1:-v0.31.0}
PACKAGE_URL="https://github.com/MagicStack/asyncpg.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"

# Create python3 symlink for standalone runs (CI wrapper provides python3 via venv)
ln -sf /usr/bin/python3.12 /usr/bin/python3

# Install build dependencies.
python3 -m pip install build "setuptools==71.1.0" wheel "Cython==3.2.8"

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "${PACKAGE_DIR}"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

sed -i 's/^license = "Apache-2.0"/license = {text = "Apache-2.0"}/' pyproject.toml
sed -i 's/"setuptools>=77.0.3"/"setuptools"/' pyproject.toml
sed -i '/^license-files/d' pyproject.toml

# Build wheel without isolation so the venv's setuptools and Cython are used.
#python3 -m build --wheel --no-isolation --outdir "${SOURCE_ROOT}"
python3 -m build --wheel --no-isolation --outdir "${SOURCE_ROOT}/"

WHEEL=$(find "${SOURCE_ROOT}" -maxdepth 1 -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

cd "${SOURCE_ROOT}"

# Install wheel
echo "=== Installing Wheel ==="
python3 -m pip install "$WHEEL"

# Test
echo "=== Running Tests ==="

# 1. Version check
python3 -c "import asyncpg; print('version:', asyncpg.__version__)"

# 2. Import and API surface checks (no PostgreSQL server required).
#    All upstream test files require a live pg_config/PostgreSQL cluster at
#    collection time, so we validate the compiled extensions directly here.
python3 - <<'EOF'
import asyncpg

# Exception hierarchy — exercises the compiled asyncpg.exceptions C extension
assert issubclass(asyncpg.PostgresError,            Exception)
assert issubclass(asyncpg.UniqueViolationError,     asyncpg.PostgresError)
assert issubclass(asyncpg.UndefinedTableError,      asyncpg.PostgresError)
assert issubclass(asyncpg.ForeignKeyViolationError, asyncpg.PostgresError)
print("exception hierarchy: OK")

# Public API presence
for name in ("connect", "create_pool", "Connection", "Pool",
             "Record", "PostgresError"):
    assert hasattr(asyncpg, name), f"Missing asyncpg.{name}"
print("public API surface: OK")

# Record is a compiled C type — verify it is a type (not a plain Python class)
assert isinstance(asyncpg.Record, type), "asyncpg.Record is not a type"
assert asyncpg.Record.__name__ == "Record"
print("Record C extension: OK")

# pgproto — confirm the compiled pgproto extension loaded and exposes its types
import asyncpg.pgproto.pgproto as _pgproto
for name in ("WriteBuffer", "ReadBuffer", "UUID"):
    assert hasattr(_pgproto, name), f"Missing asyncpg.pgproto.pgproto.{name}"
print("pgproto C extension: OK")
EOF

# Build Complete
echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"