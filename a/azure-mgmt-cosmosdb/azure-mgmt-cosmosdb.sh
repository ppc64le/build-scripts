#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : azure-mgmt-cosmosdb
# Version       : azure-mgmt-cosmosdb_9.8.0
# Source repo   : https://github.com/Azure/azure-sdk-for-python
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod.K1 <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="azure-mgmt-cosmosdb"
PACKAGE_VERSION="${1:-azure-mgmt-cosmosdb_9.8.0}"
PACKAGE_URL="https://github.com/Azure/azure-sdk-for-python"
PACKAGE_DIR="sdk/cosmos/azure-mgmt-cosmosdb"
PYPI_VERSION="${PACKAGE_VERSION#*_}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"
# tests/conftest.py requires the Azure test proxy server (localhost:5000) even
# for collection; all test classes also carry @pytest.mark.live_test_only which
# requires real Azure credentials — skip tests and verify via import smoke-test
SKIP_TESTS="true"

# =============================================================================
# CALLBACK: post_clone — navigate to the CosmosDB subdirectory and read the
# setuptools version requirement from pyproject.toml when present; falls back
# to SETUPTOOLS_VERSION="<82" for older tags that only ship setup.py
# =============================================================================
post_clone() {
    log_info "Navigating to package subdirectory: ${PACKAGE_DIR}"
    cd "${PACKAGE_DIR}"

    log_info "Reading setuptools version requirement from pyproject.toml"
    if [[ -f "pyproject.toml" ]]; then
        setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
        if [[ -n "$setuptools_req" ]]; then
            SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
            SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
            log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
        else
            log_info "No setuptools pin found in pyproject.toml — using template default"
        fi
    else
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — verify package import only; full test suite
# requires a live Azure test proxy (localhost:5000) even for collection, plus
# real Azure credentials for the @pytest.mark.live_test_only test classes
# =============================================================================
custom_test_command() {
    log_info "Verifying package import (full test suite requires Azure test proxy + credentials)"
    python -c "import azure.mgmt.cosmosdb; print('azure-mgmt-cosmosdb import OK')"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
