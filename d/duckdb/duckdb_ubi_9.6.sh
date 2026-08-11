#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : duckdb
# Version       : v1.4.3
# Source repo   : https://github.com/duckdb/duckdb-python.git
# Tested on     : UBI:9.6
# Language      : Python, C++
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Puneet Sharma <puneet.sharma21@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=duckdb-python
PACKAGE_VERSION=${1:-v1.4.3}
PACKAGE_DIR=duckdb-python
PACKAGE_URL=https://github.com/duckdb/duckdb-python.git
PYTHON_VERSION=3.11

# Install necessary system packages
dnf install -y gcc-toolset-13 make cmake ninja-build libomp-devel git python${PYTHON_VERSION} python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-devel

# Enable GCC toolset
source /opt/rh/gcc-toolset-13/enable
export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++


python${PYTHON_VERSION} -m pip install build wheel setuptools ninja pybind11

# Clone the repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

git submodule update --init --recursive

export DUCKDB_BUILD_PYTHON=1
export DUCKDB_BUILD_STATIC=1

echo "Building duckdb wheel..."
if ! python${PYTHON_VERSION} -m build --wheel; then
    echo "------------------$PACKAGE_NAME: build_fail------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fail"
    exit 1
fi

echo "Installing duckdb wheel..."
WHEEL_FILE=$(find dist -name "*.whl" | head -n1)
if [ -n "$WHEEL_FILE" ]; then
    python${PYTHON_VERSION} -m pip install "$WHEEL_FILE"
fi

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

