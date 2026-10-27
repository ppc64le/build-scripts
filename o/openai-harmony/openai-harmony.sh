#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : openai-harmony
# Version       : v0.0.4
# Source repo   : https://github.com/openai/harmony
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Rosman Cariño <rcarino@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="openai-harmony"
PACKAGE_VERSION="${1:-v0.0.4}"
PACKAGE_URL="https://github.com/openai/harmony"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel gcc-c++ make wget cmake llvm-toolset"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install maturin
# =============================================================================
pre_build() {
    log_info "Installing maturin for Rust-Python binding"
    python -m pip install maturin
}

# =============================================================================
# CALLBACK: pre_test —  install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing maturin for test environment"
    python -m pip install maturin
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"