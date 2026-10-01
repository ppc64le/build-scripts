#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : azure-mgmt-resource
# Version       : 23.4.0
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
PACKAGE_NAME="azure-mgmt-resource"
PACKAGE_VERSION="azure-mgmt-resource_23.4.0"
PACKAGE_URL="https://github.com/Azure/azure-sdk-for-python"
PACKAGE_DIR="sdk/resources/azure-mgmt-resource"
# Strip the monorepo tag prefix (e.g. "azure-mgmt-resource_23.4.0" → "23.4.0")
# so the template installs the correct PyPI version regardless of the version passed
PYPI_VERSION="${PACKAGE_VERSION#*_}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-pip"
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
# CALLBACK: pre_test — install test-only dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install python-dotenv six
    python -m pip install -r dev_requirements.txt
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"