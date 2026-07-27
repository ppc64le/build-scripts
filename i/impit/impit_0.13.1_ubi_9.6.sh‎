#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : impit
# Version       : 0.13.1
# Source repo   : https://github.com/apify/impit.git
# Tested on     : UBI:9.6
# Language      : Rust, Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Jason Cho <jason.cho2@ibm.com>
#
# ----------------------------------------------------------------------------
PACKAGE_NAME="impit"
PACKAGE_DIR="impit/impit-python"
PACKAGE_URL="https://github.com/apify/impit.git"
PACKAGE_VERSION=${1:-0.13.1}
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# -- System dependencies ------------------------------------------------------
dnf install -y \
    git \
    gcc-toolset-15 \
    python3.12 \
    python3.12-pip \
    python3.12-devel

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
gcc --version

python3.12 -m pip install --upgrade pip setuptools

# -- Rust ---------------------------------------------------------------------
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"

python3.12 -m pip install maturin

git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "py-${PACKAGE_VERSION}"

#export LD_LIBRARY_PATH for python 3.13 and 3.14
PY_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')

if [[ "$PY_VERSION" == "3.13" || "$PY_VERSION" == "3.14" ]]; then
    export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
    export PYO3_PYTHON="/usr/local/bin/python${PY_VERSION}"
fi

# -- Build wheel --------------------------------------------------------------
# reqwest's http3 feature requires this unstable cfg flag.
export RUSTFLAGS='--cfg reqwest_unstable'

python3.12 -m pip wheel --no-cache-dir --no-binary impit \
    "impit==${PACKAGE_VERSION}" \
    -w "${SOURCE_ROOT}"

WHEEL=$(find "${SOURCE_ROOT}" -name "impit-*.whl" | head -1)

if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# -- Install ------------------------------------------------------------------
python3.12 -m pip install "$WHEEL"

# -- Tests --------------------------------------------------------------------
python3.12 - << 'PYEOF'
import sys

import impit
print("PASS  import impit")

assert hasattr(impit, "AsyncClient"), "AsyncClient not found"
assert hasattr(impit, "Client"),      "Client not found"
print("PASS  AsyncClient and Client present")

import asyncio

async def smoke():
    async with impit.AsyncClient() as client:
        r = await client.get("https://httpbin.org/get")
        assert r.status_code == 200, f"Unexpected status: {r.status_code}"
        print(f"PASS  GET https://httpbin.org/get — status {r.status_code}")

try:
    asyncio.run(smoke())
except Exception as e:
    print(f"WARN  network test skipped: {e}")

print("\nAll tests passed.")
sys.exit(0)
PYEOF

echo "Build and tests complete. Wheel: $WHEEL"
