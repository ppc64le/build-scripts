#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : incremental
# Version       : incremental-24.7.2
# Source repo   : https://github.com/twisted/incremental
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="incremental"
PACKAGE_VERSION="${1:-incremental-24.7.2}"
PACKAGE_URL="https://github.com/twisted/incremental"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"
PYPI_VERSION="${PACKAGE_VERSION#incremental-}"

# =============================================================================
# CALLBACK: pre_test
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install -r requirements_tests.in
        
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
