#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : certipy
# Version       : main
# Source repo   : https://github.com/LLNL/certipy
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vipul Ajmera <Vipul.Ajmera@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="certipy"
PACKAGE_VERSION="${1:-0.2.2}"
PACKAGE_URL="https://github.com/LLNL/certipy"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="curl gcc gcc-c++ git make openssl-devel pkg-config python3 python3-devel python3-pip yum-utils"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

pre_test() {
    log_info "Installing test dependencies..."
    python -m pip install flask setuptools "setuptools_scm>=7" "cryptography<42"
}

# =============================================================================
# Execute the build (invokes the Python template).
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
