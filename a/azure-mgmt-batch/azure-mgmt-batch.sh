#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : azure-mgmt-batch
# Version       : azure-mgmt-batch_18.0.0
# Source repo   : https://github.com/Azure/azure-sdk-for-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod.K1 <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="azure-mgmt-batch"
PACKAGE_VERSION="${1:-azure-mgmt-batch_18.0.0}"
PACKAGE_URL="https://github.com/Azure/azure-sdk-for-python"
PACKAGE_DIR="sdk/batch/azure-mgmt-batch"
PYPI_VERSION="${PACKAGE_VERSION#*_}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# CALLBACK: post_clone — change into the azure-mgmt-batch subdirectory of the monorepo
# =============================================================================
post_clone() {
    log_info "Navigating to package subdirectory: ${PACKAGE_DIR}"
    cd "${PACKAGE_DIR}"
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies for azure-mgmt-batch;
# six is required by devtools_testutils (azure-sdk-tools) used in conftest.py;
# azure-sdk-tools must be installed from the monorepo local path so that
# devtools_testutils imports resolve correctly
# =============================================================================
pre_test() {
    log_info "Installing required test dependencies"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install six python-dotenv
    # Install azure-sdk-tools from the monorepo so devtools_testutils is available
    python -m pip install -e ../../../tools/azure-sdk-tools
    python -m pip install -r dev_requirements.txt
}

# =============================================================================
# CALLBACK: custom_test_command — run tests with the tests/ directory on
# PYTHONPATH so that the local mgmt_batch_preparers helper module is importable
# (CWD is already sdk/batch/azure-mgmt-batch/ from post_clone; tests/ is relative)
# =============================================================================
custom_test_command() {
    log_info "Running tests for ${PACKAGE_NAME}"
    # CWD is sdk/batch/azure-mgmt-batch/ (set by post_clone).
    # Prepend tests/ to PYTHONPATH so mgmt_batch_preparers is importable as a
    # local module — it lives in tests/ and is not an installed package.
    PYTHONPATH="tests${PYTHONPATH:+:${PYTHONPATH}}" \
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        tests
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
