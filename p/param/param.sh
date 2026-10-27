#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : param
# Version       : v2.1.0
# Source repo   : https://github.com/holoviz/param
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Anumala Rajesh <Anumala.Rajesh@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="param"
PACKAGE_VERSION="${1:-v2.1.0}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://github.com/holoviz/param"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# CALLBACK: pre_build — install hatchling build backend to fix 'Cannot import hatchling.build'
# =============================================================================
pre_build() {
    log_info "Installing hatchling build backend required by pyproject.toml"
    python -m pip install --upgrade pip hatchling
}

# =============================================================================
# CALLBACK: pre_test — mirror build backend deps and install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing build backend and test dependencies"
    python -m pip install --upgrade pip setuptools wheel hatchling
    python -m pip install pytest-asyncio
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"