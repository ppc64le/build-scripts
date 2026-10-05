#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : azure-mgmt-dns
# Version       : azure-mgmt-dns_8.2.0
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
PACKAGE_NAME="azure-mgmt-dns"
PACKAGE_VERSION="azure-mgmt-dns_8.2.0"
PACKAGE_URL="https://github.com/Azure/azure-sdk-for-python"
PACKAGE_DIR="sdk/network/azure-mgmt-dns"
PYPI_VERSION="${PACKAGE_VERSION#*_}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 git libffi libffi-devel make openssl openssl-devel python3 python3-devel python3-pip rust-toolset wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# CALLBACK: post_clone — change into the azure-mgmt-dns subdirectory of the monorepo
# =============================================================================
post_clone() {
    log_info "Navigating to package subdirectory: ${PACKAGE_DIR}"
    cd "${PACKAGE_DIR}"
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies for azure-mgmt-dns
# =============================================================================
pre_test() {
    log_info "Installing required test dependencies"
    python -m pip install python-dotenv six
    python -m pip install -r dev_requirements.txt
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"