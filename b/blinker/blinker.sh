#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : blinker
# Version       : rel-1.4
# Source repo   : https://github.com/pallets-eco/blinker
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="blinker"
PACKAGE_VERSION="${1:-rel-1.4}"
PACKAGE_URL="https://github.com/pallets-eco/blinker"

NOARCH="true"

PYPI_VERSION="${PACKAGE_VERSION#rel-}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ gcc-gfortran git make openssl-devel python-devel wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test
# =============================================================================
pre_test() {
    log_info "running pre_test hook" 
    python -m pip install pytest-asyncio nose
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"