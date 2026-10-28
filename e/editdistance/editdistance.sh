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
# Normalize version: ensure leading 'v' prefix to match upstream git tags (e.g. v0.8.1)
PACKAGE_VERSION="v${PACKAGE_VERSION#v}"
RUST_VERSION="1.75.0"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-c++ gcc-toolset-13 git make python3-devel"
DEB_DEP_PKGS="cmake g++ git make python3-dev python3-venv"
SLES_DEP_PKGS="cmake gcc-c++ git make python3-devel"

# =============================================================================
# CALLBACK: pre_build — set up Rust toolchain and install build dependencies
# =============================================================================
pre_build() {
    log_info "Setting up Rust toolchain..."

    # Redirect RUSTUP_HOME to writable home directory to avoid permission issues on /opt
    export RUSTUP_HOME="${HOME}/.rustup"

    # Use Rust 1.75.0 for editdistance v0.8.1 compatibility
    log_info "Installing Rust ${RUST_VERSION}..."
    rustup install ${RUST_VERSION}
    export RUSTUP_TOOLCHAIN="${RUST_VERSION}"

    log_info "Using Rust: $(rustc --version)"
    log_info "Using Cargo: $(cargo --version)"

    log_info "Installing build dependencies..."
    python -m pip install pdm-backend cython
}

# =============================================================================
# CALLBACK: pre_test — set Rust toolchain default and install test dependencies
# =============================================================================
pre_test() {
    log_info "Setting Rust ${RUST_VERSION} as default for test environment..."
    export RUSTUP_HOME="${HOME}/.rustup"
    export RUSTUP_TOOLCHAIN="${RUST_VERSION}"

    log_info "Installing test dependencies..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install pdm-backend cython
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"