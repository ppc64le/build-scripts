#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : nbformat
# Version       : v5.10.4
# Source repo   : https://github.com/jupyter/nbformat
# Tested on     : UBI:9.6 
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="nbformat"
PACKAGE_VERSION="${1:-v5.10.4}"
PACKAGE_URL="https://github.com/jupyter/nbformat"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip openssl-devel openssl gcc-toolset-13"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: Pre-test hook
# =============================================================================
pre_test() {
    # Install test dependencies
    log_info "Installing test dependencies.."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install hatch testpath packaging
    python -m pip install nbformat[test]
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"