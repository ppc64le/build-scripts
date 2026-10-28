#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : lingua-language-detector
# Version       : v1.8.0
# Source repo   : https://github.com/pemistahl/lingua-rs
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vijay Vinnakota <vijay.vinnakota@ibm.com>
# -------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="lingua-language-detector"
PACKAGE_VERSION="${1:-v1.8.0}"
PACKAGE_URL="https://github.com/pemistahl/lingua-rs"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make openssl-devel libffi-devel zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_clone — map Python package version to Rust crate git tag
#
# The lingua-rs repo is tagged by Rust crate version (e.g. v1.8.0), but
# powercore passes the Python package version (e.g. 2.2.0).  Translate the
# incoming version so the template checks out the correct tag.
# =============================================================================
pre_clone() {
    # Normalise: strip a leading 'v' if present so both "2.2.0" and "v2.2.0" work
    local py_ver="${PACKAGE_VERSION#v}"

    case "$py_ver" in
        2.2.0) PACKAGE_VERSION="v1.8.0" ;;
        2.1.1) PACKAGE_VERSION="v1.7.2" ;;
        2.1.0) PACKAGE_VERSION="v1.7.1" ;;
        2.0.2) PACKAGE_VERSION="v1.6.2" ;;
        # Rust-crate tags (v1.x.x) — pass through unchanged
        1.*) PACKAGE_VERSION="v${py_ver}" ;;
        *)
            log_info "WARNING: No Python→Rust version mapping for ${PACKAGE_VERSION}; using as-is"
            ;;
    esac

    log_info "Resolved PACKAGE_VERSION to git tag: ${PACKAGE_VERSION}"
}

# =============================================================================
# CALLBACK: pre_build — set stable Rust toolchain and install maturin build backend
#
# Sets RUSTUP_HOME to ~/.rustup to avoid permission errors when writing to the
# container-owned /opt/rust/rustup directory.
# lingua-rs v1.8.0 uses Rust edition 2024 (requires Rust >= 1.85.0); stable
# toolchain satisfies this requirement.
# =============================================================================
pre_build() {
    log_info "Setting up Rust stable toolchain..."
    # Redirect RUSTUP_HOME to a writable directory to avoid permission errors on /opt
    export RUSTUP_HOME="${HOME}/.rustup"
    rustup install stable
    export RUSTUP_TOOLCHAIN="stable"
    log_info "Using Rust: $(rustc --version)"

    log_info "Installing maturin build backend"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install maturin
}

# =============================================================================
# CALLBACK: pre_test — set stable Rust toolchain and install test deps
#
# Mirrors pre_build() Rust setup — .venv-test does not inherit from .venv-build.
# =============================================================================
pre_test() {
    log_info "Setting up Rust stable toolchain for test environment..."
    # Redirect RUSTUP_HOME to a writable directory to avoid permission errors on /opt
    export RUSTUP_HOME="${HOME}/.rustup"
    export RUSTUP_TOOLCHAIN="stable"
    log_info "Using Rust: $(rustc --version)"

    log_info "Installing build backend and test dependencies"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install maturin
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest from the tests/python subdirectory
# The test suite lives under tests/python/ (not tests/) in the lingua-rs repo.
# =============================================================================
custom_test_command() {
    log_info "Running upstream Python tests from tests/python/ subdirectory"
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        tests/python/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"