#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : editdistance
# Version       : v0.8.1
# Source repo   : https://github.com/roy-ht/editdistance
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="editdistance"
PACKAGE_VERSION="${1:-v0.8.1}"
PACKAGE_URL="https://github.com/roy-ht/editdistance"

RUST_VERSION="1.75.0"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-c++ gcc-toolset-13 git make python3-devel"
DEB_DEP_PKGS="cmake g++ git make python3-dev python3-venv"
SLES_DEP_PKGS="cmake gcc-c++ git make python3-devel"

# =============================================================================
# CALLBACK: pre_build — install pdm-backend build backend and set Rust 1.75.0 toolchain
# =============================================================================
pre_build() {
    log_info "Installing build dependencies..."
    python -m pip install pdm-backend cython

    log_info "Setting up Rust ${RUST_VERSION} toolchain for ${PACKAGE_NAME} ${PACKAGE_VERSION}..."
    rustup install ${RUST_VERSION}
    rustup default ${RUST_VERSION}
}

# =============================================================================
# CALLBACK: pre_test — ensure Rust toolchain is available in test environment
# =============================================================================
pre_test() {
    log_info "Setting Rust ${RUST_VERSION} as default for test environment..."
    rustup default ${RUST_VERSION}

    log_info "Installing test dependencies..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install pdm-backend cython
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
