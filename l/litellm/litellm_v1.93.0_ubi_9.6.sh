#!/bin/bash
# -----------------------------------------------------------------------------
# Package       : litellm
# Version       : v1.93.0
# Source repo   : https://github.com/BerriAI/litellm
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

PACKAGE_DIR="litellm"
PACKAGE_NAME="litellm"
PACKAGE_VERSION=${1:-v1.93.0}
PACKAGE_URL="https://github.com/BerriAI/litellm.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"

# Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
export PATH="$HOME/.cargo/bin:$PATH"

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

# Copy wheel to /home/tester so the wrapper script can locate it without rebuilding
cp "${WHEEL}" /home/tester/

cd "${SOURCE_ROOT}"

# Install wheel + test dependencies
echo "=== Installing Wheel ==="
python3.12 -m pip install "${WHEEL}"
python3.12 -m pip install pytest pytest-asyncio pytest-timeout

# Run tests
echo "=== Running Tests ==="

# 1. Version check
python3.12 -c "import importlib.metadata; print('litellm version:', importlib.metadata.version('litellm'))"

# 2. Upstream unit tests — skip any that require live API keys or external services.
#    The marker filter avoids integration test functions that call real LLM endpoints.
cd "${PACKAGE_DIR}"
python3.12 -m pytest \
    tests/test_litellm/test_filter_out_litellm_params.py \
    tests/test_litellm/test_model_cost_aliases.py \
    tests/test_litellm/test_count_tokens_public_api.py \
    tests/test_litellm/test_cost_calculator.py \
    tests/test_litellm/test_exception_mapping_request_attribute.py \
    -v \
    --timeout=60 \
    -k "not test_extract_cache" \
    -x

TEST_EXIT=$?
cd "${SOURCE_ROOT}"

if [ "$TEST_EXIT" -ne 0 ]; then
    echo "ERROR: Tests failed (exit $TEST_EXIT)"
    exit "$TEST_EXIT"
fi

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"