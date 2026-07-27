#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : couchbase
# Version          : 4.6.2
# Source repo      : https://github.com/couchbase/couchbase-python-client
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
PACKAGE_DIR="couchbase-python-client"
PACKAGE_NAME="couchbase"
PACKAGE_VERSION=${1:-4.6.2}
PACKAGE_URL="https://github.com/couchbase/couchbase-python-client.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y \
    gcc-toolset-13 \
    git \
    cmake \
    ninja-build \
    python3.12 \
    python3.12-devel \
    python3.12-pip \
    openssl-devel \
    zlib-devel

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"

# Install Rust toolchain (required by some couchbase-cxx-client components)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
export PATH="$HOME/.cargo/bin:$PATH"

# Install build frontend and build-time Python dependencies
python3.12 -m pip install --upgrade pip
python3.12 -m pip install build setuptools wheel cmake scikit-build

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "${PACKAGE_DIR}"
git checkout "$PACKAGE_VERSION"
git submodule update --init --recursive --depth 1

# Disable the CPM cache check — by default pycbc_build_setup.py requires a
# pre-populated deps/couchbase-cxx-cache directory (PYCBC_USE_CPM_CACHE=true).
# Setting it to false lets CMake/CPM download dependencies at build time instead.
export PYCBC_USE_CPM_CACHE=false

# Build wheel (--no-build-isolation ensures the cmake/scikit-build installed
# above are visible during the CMake extension build)
python3.12 -m pip wheel . --no-deps --no-build-isolation -w "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "${PACKAGE_NAME}-*.whl" | head -1)
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

# Install wheel + test dependencies
echo "=== Installing Wheel ==="
python3.12 -m pip install "${WHEEL}"
python3.12 -m pip install pytest pytest-asyncio pytest-timeout

# Run tests
echo "=== Running Tests ==="

# 1. Version check (runs from SOURCE_ROOT — never inside the source tree)
python3.12 -c "import importlib.metadata; print('couchbase version:', importlib.metadata.version('couchbase'))"

# 2. Smoke tests — run from a temp directory OUTSIDE the source tree so that
#    Python resolves 'couchbase' from the installed wheel, not the local source
#    directory (which lacks the compiled _core.so extension).
#    The upstream test suite has no cluster-free unit tests at this tag; all
#    fixtures require a live Couchbase node.  We therefore write a minimal
#    standalone test that exercises the installed package's public API surface.
SMOKE_DIR=$(mktemp -d)
cat > "${SMOKE_DIR}/test_smoke.py" << 'PYEOF'
import importlib.metadata
import pytest

def test_version():
    version = importlib.metadata.version("couchbase")
    assert version == "4.6.2", f"Unexpected version: {version}"

def test_import_top_level():
    import couchbase
    assert hasattr(couchbase, "__version__")

def test_import_auth():
    from couchbase.auth import PasswordAuthenticator, CertificateAuthenticator
    pa = PasswordAuthenticator("user", "pass")
    assert pa is not None

def test_import_options():
    from couchbase.options import ClusterOptions
    from couchbase.auth import PasswordAuthenticator
    opts = ClusterOptions(PasswordAuthenticator("u", "p"))
    assert opts is not None

def test_import_exceptions():
    from couchbase.exceptions import (
        CouchbaseException,
        DocumentNotFoundException,
        TimeoutException,
        AuthenticationException,
    )

def test_import_n1ql():
    from couchbase.n1ql import N1QLQuery
    q = N1QLQuery("SELECT 1")
    assert q is not None

def test_import_search():
    from couchbase.search import SearchOptions, TermQuery
    q = TermQuery("hello", field="name")
    assert q is not None

def test_import_management():
    from couchbase.management.buckets import BucketManager
    from couchbase.management.collections import CollectionManager
    from couchbase.management.users import UserManager

def test_import_analytics():
    from couchbase.analytics import AnalyticsQuery, AnalyticsScanConsistency
    q = AnalyticsQuery("SELECT 1")
    assert q is not None

def test_import_acouchbase():
    from acouchbase.cluster import Cluster as AsyncCluster
    assert AsyncCluster is not None

def test_import_transactions():
    from couchbase.transactions import Transactions
    assert Transactions is not None
PYEOF

python3.12 -m pytest "${SMOKE_DIR}/test_smoke.py" \
    -v \
    --timeout=60 \
    -x

TEST_EXIT=$?
rm -rf "${SMOKE_DIR}"

if [ "$TEST_EXIT" -ne 0 ]; then
    echo "ERROR: Tests failed (exit $TEST_EXIT)"
    exit "$TEST_EXIT"
fi

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"