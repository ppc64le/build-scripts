#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : python-oracledb
# Version       : v2.5.1
# Source repo   : https://github.com/oracle/python-oracledb
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Anumala Rajesh <Anumala.Rajesh@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="python-oracledb"
PACKAGE_VERSION="${1:-v2.5.1}"
PACKAGE_URL="https://github.com/oracle/python-oracledb"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git openssl-devel python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""


# =============================================================================
# CALLBACK: pre_build — Install Cython build dependency (required for compiling extensions)
# =============================================================================
pre_build() {
    log_info "Installing Cython build dependency"
    python -m pip install "cython>=3.0"
}

# =============================================================================
# CALLBACK: custom_test_command — Run import-based smoke tests (full test suite requires Oracle DB connection)
# =============================================================================
custom_test_command() {
    log_info "Running import smoke tests"
    
    python -c "import oracledb; print('oracledb version:', oracledb.__version__)"
    python -c "import oracledb; print('oracledb location:', oracledb.__file__)"
    
    log_info "Import tests passed successfully"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

