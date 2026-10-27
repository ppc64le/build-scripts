#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : argon2-cffi-bindings
# Version       : 21.2.0
# Source repo   : https://github.com/hynek/argon2-cffi-bindings
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="argon2-cffi-bindings"
PACKAGE_VERSION="${1:-21.2.0}"
PACKAGE_URL="https://github.com/hynek/argon2-cffi-bindings"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git make python3 python3-devel python3-pip"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv libffi-dev libssl-dev"
SLES_DEP_PKGS="git python3-devel python3-pip libffi-devel libopenssl-devel"

SETUPTOOLS_VERSION=">=70.1,<82"

pre_build() {
    log_info "Installing build dependencies..."
    python -m pip install setuptools-scm "cffi>=1.0.1"
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
