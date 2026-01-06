#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package         : mcp-context-forge
# Version         : v0.9.0
# Source repo     : https://github.com/IBM/mcp-context-forge
# Tested on       : UBI:9.6
# Ci-Check        : True
# Language        : Python
# Script License  : Apache License 2.0
# Maintainer      : Sanket Patil <Sanket.Patil11@ibm.com>
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=mcp-context-forge
PACKAGE_VERSION=${1:-v0.9.0}
PACKAGE_URL=https://github.com/IBM/mcp-context-forge
PACKAGE_DIR=mcp-context-forge

SCRIPT_PATH=$(dirname "$(realpath "$0")")
BUILD_HOME=${PWD}

# Install dependencies
yum install -y git make wget curl python3.12 python3.12-devel python3.12-pip gcc gcc-c++ libffi-devel openssl-devel rust cargo sqlite pkgconf-pkg-config libxml2-devel libxslt-devel jq --allowerasing

curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

# Upgrade pip tooling (system-wide)
python3.12 -m pip install --upgrade pip setuptools wheel

# Clone repository
cd ${BUILD_HOME}
git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}

# Apply patch to use python3.12 and skip flaky tests.
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

# Environment setup
if [ ! -f .env ]; then
    cp .env.example .env
fi

# install uv
if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Increase uv network timeout for ppc64le runners
export UV_HTTP_TIMEOUT=300
export UV_HTTP_RETRIES=5

# Remove any existing venv to avoid conflicts
rm -rf /root/.venv/mcpgateway

# ensure Makefile uses python3.12
export PYTHON=python3.12

# Create venv via Makefile
make venv install

# Build
if ! make install-dev; then
    echo "ERROR: $PACKAGE_NAME - Build failed."
    exit 1
else
    echo "INFO: $PACKAGE_NAME - Build successful."
fi

# Run tests
export DATABASE_URL="sqlite:///:memory:"
export TEST_DATABASE_URL="sqlite:///:memory:"

make autoflake isort black

if ! make test; then
    echo "ERROR: $PACKAGE_NAME - Test phase failed."
    exit 2
else
    echo "INFO: $PACKAGE_NAME - All tests passed."
fi

echo "SUCCESS: $PACKAGE_NAME version $PACKAGE_VERSION built and tested successfully."
exit 0
