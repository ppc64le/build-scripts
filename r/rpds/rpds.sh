#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package          : rpds
# Version          : v0.22.3
# Source repo      : https://github.com/crate-py/rpds
# Tested on        : UBI:9.6
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2.0 or later
# Maintainer       : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="rpds"
PACKAGE_VERSION="${1:-v0.22.3}"
PACKAGE_URL="https://github.com/crate-py/rpds"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — Install Rust-based build dependencies (maturin)
# =============================================================================
pre_build() {
    log_info "Installing build dependencies..."
    python -m pip install "maturin>=1.2,<2.0"
}

# =============================================================================
# CALLBACK: pre_test — Install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."
    python -m pip install "pytest>=7.0"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
