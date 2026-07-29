#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : duckdb
# Version       : v1.5.4
# Source repo   : https://github.com/duckdb/duckdb-python.git
# Tested on     : UBI:10.2
# Language      : Python, C++
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Jason Cho <jason.cho2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=duckdb-python
PACKAGE_VERSION=${1:-v1.5.4}
PACKAGE_DIR=duckdb-python
PACKAGE_URL=https://github.com/duckdb/duckdb-python.git
PYTHON_VERSION=3.12

# Install necessary system packages
dnf install -y \
    gcc-toolset-15 \
    cmake \
    ninja-build \
    python3.12 \
    python3.12-devel \
    python3.12-pip

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
gcc --version

python3.12 -m pip install --upgrade pip setuptools

# -- Build wheel --------------------------------------------------------------
pip3.12 wheel --no-cache-dir --only-binary :none "duckdb==${PACKAGE_VERSION}" -w "${CURRENT_DIR}/dist/"

WHEEL=$(find "${CURRENT_DIR}/dist" -name "duckdb-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# -- Install ------------------------------------------------------------------
cd dist
pip3.12 install "$WHEEL"

# Run tests
cd /

if ! python${PYTHON_VERSION} - <<EOF
import duckdb

# Ensure correct package loaded
assert hasattr(duckdb, "connect"), "duckdb.connect missing"

con = duckdb.connect()

# 1 Basic SQL test
assert con.execute("select 42").fetchall() == [(42,)]

# 2 Version check (SQL side)
version_sql = con.execute("select version()").fetchone()[0]
assert version_sql.startswith("${PACKAGE_VERSION}")

# 3 Python package version check
assert duckdb.__version__ == "${PACKAGE_VERSION#v}"

print("All DuckDB runtime tests passed.")
EOF
then
    echo "------------------$PACKAGE_NAME: Tests_Fail------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install & Test Success ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
