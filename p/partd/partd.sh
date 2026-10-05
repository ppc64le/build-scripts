#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : partd
# Version       : 1.4.2
# Source repo   : https://github.com/dask/partd
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="partd"
PACKAGE_VERSION="${1:-1.4.2}"
PACKAGE_URL="https://github.com/dask/partd"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git make python3 python3-devel python3-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH=true

# =============================================================================
# CALLBACK: pre_test — Install test dependencies before running tests
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install -r requirements.txt
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
