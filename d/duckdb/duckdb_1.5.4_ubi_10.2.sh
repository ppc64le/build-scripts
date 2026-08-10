#!/bin/bash -e
#
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

set -e

PACKAGE_NAME=duckdb-python
PACKAGE_VERSION=${1:-v1.5.4}
PACKAGE_DIR=duckdb-python
PACKAGE_URL=https://github.com/duckdb/duckdb-python.git
PYTHON_VERSION=${2:-3.12}
SOURCE_ROOT="$(pwd)"

# Install necessary system packages
dnf install -y git gcc-toolset-15 make cmake ninja-build libomp-devel python3 python3-devel python3-pip

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
gcc --version

python${PYTHON_VERSION} -m pip install --upgrade pip setuptools build wheel ninja pybind11

# Clone the repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

# Populate the DuckDB C++ engine submodule — without this the CMake
# configure step fails because external/duckdb/ is an empty directory.
git submodule update --init --recursive

export DUCKDB_BUILD_PYTHON=1
export DUCKDB_BUILD_STATIC=1

# -- Build wheel --------------------------------------------------------------
python${PYTHON_VERSION} -m build --wheel

WHEEL=$(find dist -name "duckdb-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# Copy wheel to /home/tester so the wrapper script can locate it without rebuilding
if [ -d /home/tester ]; then
    cp "${WHEEL}" /home/tester/
fi

cd "${SOURCE_ROOT}"

# -- Install ------------------------------------------------------------------
python${PYTHON_VERSION} -m pip install "${PACKAGE_DIR}/${WHEEL}"

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