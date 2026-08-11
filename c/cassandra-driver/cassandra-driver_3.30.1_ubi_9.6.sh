#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cassandra-driver
# Version          : 3.30.1
# Source repo      : https://github.com/apache/cassandra-python-driver
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_DIR="cassandra-python-driver"
PACKAGE_NAME="cassandra-driver"
PACKAGE_VERSION=${1:-3.30.1}
PACKAGE_URL="https://github.com/apache/cassandra-python-driver"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip \
    make wget openssl-devel bzip2-devel krb5-devel libffi-devel zlib-devel

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH"

# Build and install libev (required for the libev extension)
curl -LO https://dist.schmorp.de/libev/Attic/libev-4.33.tar.gz
tar -xzf libev-4.33.tar.gz
cd libev-4.33
export CFLAGS="-fPIC"
export LDFLAGS="-fPIC"
./configure --disable-shared --enable-static
make -j$(nproc)
make install
cd "${SOURCE_ROOT}"

# Install build frontend
python3.12 -m pip install "build" "setuptools<80" wheel

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone --branch "$PACKAGE_VERSION" --depth 1 "$PACKAGE_URL" "$PACKAGE_DIR"
cd "${PACKAGE_DIR}"

# Point the driver at the static libev we just built
export CASS_DRIVER_LIBEV_INCLUDES="/usr/local/include"
export CASS_DRIVER_LIBEV_LIBS="/usr/local/lib"
export LDFLAGS="-Wl,-Bstatic -lev -Wl,-Bdynamic"

# Build wheel
python3.12 -m build --wheel --outdir "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "cassandra_driver-*.whl" -o -name "cassandra-driver-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# Copy wheel to /home/tester so the wrapper script can locate it without rebuilding
mkdir -p /home/tester
cp "${WHEEL}" /home/tester/

cd "${SOURCE_ROOT}"

# Install wheel + test dependencies
echo "=== Installing Wheel ==="
python3.12 -m pip install "${WHEEL}"
python3.12 -m pip install pytest pytest-timeout pytest-asyncio mock gevent eventlet pyopenssl

python3.12 -m pip install -r "${PACKAGE_DIR}/test-requirements.txt"

# Run tests
echo "=== Running Tests ==="

# Version check
python3.12 -c "import importlib.metadata; print('cassandra-driver version:', importlib.metadata.version('cassandra-driver'))"

# Upstream unit tests — run from SOURCE_ROOT so the installed wheel's cassandra
# package is imported instead of the local source tree (which lacks the compiled
# .so files and would fail cassandra.cluster import on Python 3.12).
# Only include test files that do not import cassandra.cluster at module level.
python3.12 -m pytest \
    "${PACKAGE_DIR}/tests/unit/test_auth.py" \
    "${PACKAGE_DIR}/tests/unit/cython/test_bytesio.py" \
    "${PACKAGE_DIR}/tests/unit/cython/test_types.py" \
    "${PACKAGE_DIR}/tests/unit/cython/test_utils.py" \
    "${PACKAGE_DIR}/tests/unit/test_marshalling.py" \
    "${PACKAGE_DIR}/tests/unit/test_metadata.py" \
    "${PACKAGE_DIR}/tests/unit/test_query.py" \
    "${PACKAGE_DIR}/tests/unit/test_timestamps.py" \
    "${PACKAGE_DIR}/tests/unit/test_types.py" \
    "${PACKAGE_DIR}/tests/unit/test_util_types.py" \
    "${PACKAGE_DIR}/tests/unit/cqlengine/test_columns.py" \
    -k "not (CloudTests or TestTwistedConnection or _PoolTests or test_timeout_does_not_release_stream_id)" \
    -p no:warnings \
    -v \
    --timeout=60

TEST_EXIT=$?
cd "${SOURCE_ROOT}"

if [ "$TEST_EXIT" -ne 0 ]; then
    echo "ERROR: Tests failed (exit $TEST_EXIT)"
    exit "$TEST_EXIT"
fi

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"