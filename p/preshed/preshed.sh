#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : preshed
# Version       : release-v3.0.13
# Source repo   : https://github.com/explosion/preshed
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="preshed"
PACKAGE_VERSION="${1:-release-v3.0.13}"
PACKAGE_URL="https://github.com/explosion/preshed"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git make python3-devel python3-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build
# =============================================================================
pre_build() {
    log_info "Installing build dependencies..."
    python -m pip install -r requirements.txt
}

# =============================================================================
# CALLBACK: pre_test
# Install build backend deps into the test venv so pip can build preshed from
# source (avoids BackendUnavailable issues)
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."
    python -m pip install -r requirements.txt
}

# =============================================================================
# CALLBACK: custom_test_command
# Use --import-mode=importlib so pytest resolves imports from the installed
# package instead of the source tree (avoids compiled extension shadowing error)
# =============================================================================
custom_test_command() {
    log_info "Running preshed tests..."
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --pyargs preshed
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
