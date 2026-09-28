#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : azure-mgmt-redis
# Version       : azure-mgmt-redis_14.5.0
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
PACKAGE_NAME="azure-mgmt-redis"
PACKAGE_VERSION="${1:-azure-mgmt-redis_14.5.0}"
PACKAGE_URL="https://github.com/Azure/azure-sdk-for-python"
PACKAGE_DIR="sdk/redis/azure-mgmt-redis"
# Strip the monorepo tag prefix (e.g. "azure-mgmt-redis_14.5.0" → "14.5.0")
# so the template installs the correct PyPI version regardless of the version passed
PYPI_VERSION="${PACKAGE_VERSION#*_}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# CALLBACK: post_clone — change into the package subdirectory within the monorepo
# =============================================================================
post_clone() {
    log_info "Changing into package subdirectory: ${PACKAGE_DIR}"
    cd "${PACKAGE_DIR}"
}

# =============================================================================
# CALLBACK: pre_test — install build backend and test-only dependencies
# =============================================================================
pre_test() {
    log_info "Installing build backend dependencies in the test environment"
    python -m pip install --upgrade pip setuptools wheel

    log_info "Installing test dependencies"
    python -m pip install python-dotenv six
    python -m pip install -r dev_requirements.txt
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
