#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : fastapi
# Version       : 0.135.1
# Source repo   : https://github.com/fastapi/fastapi.git
# Tested on     : UBI:9.7
# Ci-Check      : True
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

PACKAGE_NAME=fastapi
PACKAGE_VERSION=${1:-0.135.1}
PACKAGE_URL=https://github.com/fastapi/fastapi.git
PACKAGE_DIR=fastapi

# Utilizing IBM ppc64le wheel index as a fallback for missing PyPI wheels
IBM_WHEEL_INDEX=https://wheels.developerfirst.ibm.com/ppc64le/linux

# 1. Install OS Dependencies
echo ">>> Installing system build dependencies..."
yum install -y \
    git make wget python3.12 python3.12-devel python3.12-pip \
    gcc gcc-c++ openssl openssl-devel \
    libffi libffi-devel sqlite pkgconf-pkg-config \
    autoconf automake libtool m4 --allowerasing

# 2. Install Rust
echo ">>> Installing Rust toolchain..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"
source "$HOME/.cargo/env"

# 3. Setup uv
echo ">>> Installing uv package manager..."
python3.12 -m pip install --upgrade pip
python3.12 -m pip install uv
# Ensure uv is in PATH
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

export UV_HTTP_TIMEOUT=300
export UV_HTTP_RETRIES=5
export PYTHON=python3.12

# 4. Clone fastapi package
echo ">>> Cloning repository..."
if [ -d "$PACKAGE_DIR" ]; then
    echo ">>> Removing existing directory $PACKAGE_DIR..."
    rm -rf "$PACKAGE_DIR"
fi
git clone $PACKAGE_URL $PACKAGE_DIR
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# 5. Create Virtual Environment & Install Package
echo ">>> Creating virtual environment with Python 3.12..."
uv venv .venv --python $PYTHON
source .venv/bin/activate

echo ">>> Installing dependencies and fastapi..."
# Note: FastAPI uses dependency-groups (PEP 735) and optional-dependencies (standard)
# We use .[standard] for the CLI and --group tests for unit tests
# We skip the 'dev' group because it includes 'playwright', which is not available on ppc64le
# We add 'black' to provide formatting support for inline-snapshot
if ! uv pip install -e ".[standard]" --group tests black \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "ERROR: $PACKAGE_NAME - Dependency installation failed."
    exit 1
fi

# 6. Validation
echo ">>> Validating FastAPI CLI execution..."
if ! fastapi --help >/dev/null; then
    echo "ERROR: $PACKAGE_NAME - fastapi CLI failed to execute."
    exit 2
else
    echo "INFO: fastapi CLI executed successfully."
fi

# 7. Run Test Suite
echo ">>> Running test suite..."
# Set PYTHONPATH to include documentation source (needed for tutorial tests)
export PYTHONPATH=./docs_src
# we run tests/ and scripts/tests/ like in scripts/test.sh to cover all functional tests
if ! pytest tests/ scripts/tests/ -v; then
    echo "ERROR: $PACKAGE_NAME - Test suite failed."
    exit 2
else
    echo "INFO: $PACKAGE_NAME - All tests passed."
fi

echo "========================================================================"
echo " SUCCESS: $PACKAGE_NAME version $PACKAGE_VERSION built and tested successfully."
echo "========================================================================"
exit 0
