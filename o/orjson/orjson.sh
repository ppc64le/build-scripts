#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : orjson
# Version       : 3.12.0
# Source repo   : https://github.com/ijl/orjson
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Prerna Kumbhar <Prerna.Kumbhar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="orjson"
PACKAGE_VERSION="${1:-3.12.0}"
PACKAGE_URL="https://github.com/ijl/orjson"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make cmake ninja-build python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — setup Rust toolchain and install maturin
# =============================================================================
pre_build() {
    log_info "Installing maturin build tool"
    python -m pip install maturin
}

# =============================================================================
# CALLBACK: pre_test — ensure Rust toolchain and maturin for test environment
# =============================================================================
pre_test() {
    log_info "Installing build backend and maturin for test environment"
    python -m pip install maturin
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
