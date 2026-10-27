#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ormsgpack
# Version       : 1.12.2
# Source repo   : https://github.com/aviramha/ormsgpack
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ormsgpack"
PACKAGE_VERSION="${1:-1.12.2}"
PACKAGE_URL="https://github.com/aviramha/ormsgpack"
RUST_VERSION="1.82.0"

# =============================================================================
# REQUIRED: Dependencies
# Note: rust/cargo are provided by the container image
# =============================================================================
RH_DEP_PKGS="git openssl-devel bzip2-devel libffi-devel zlib-devel python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — patch Cargo.toml to disable the unstable-simd default
# feature for v1.9.1. The default feature set includes "unstable-simd" which
# enables bytecount/generic-simd — a nightly-only API that fails on stable Rust.
# Fix: replace default = ["unstable-simd"] with default = [] to use the scalar
# fallback path, which compiles cleanly on stable.
# =============================================================================
post_clone() {
    if [[ "${PACKAGE_VERSION}" == "1.9.1" ]]; then
        log_info "Patching Cargo.toml: disabling unstable-simd default feature for stable Rust compatibility..."
        sed -i 's/^default = \["unstable-simd"\]/default = []/' Cargo.toml
        log_info "Patched Cargo.toml [features] default: $(grep '^default' Cargo.toml)"
    fi
}

# =============================================================================
# CALLBACK: pre_build — set up Rust toolchain and install maturin build tool
# =============================================================================
pre_build() {
    log_info "Setting up Rust toolchain..."

    # Redirect RUSTUP_HOME to writable home directory to avoid permission issues on /opt
    export RUSTUP_HOME="${HOME}/.rustup"

    # Use Rust ${RUST_VERSION} for ${PACKAGE_NAME} ${PACKAGE_VERSION} compatibility
    log_info "Installing Rust ${RUST_VERSION}..."
    rustup install ${RUST_VERSION}
    export RUSTUP_TOOLCHAIN="${RUST_VERSION}"

    log_info "Using Rust: $(rustc --version)"
    log_info "Using Cargo: $(cargo --version)"

    log_info "Installing maturin build tool..."
    python -m pip install --upgrade pip maturin
}

# =============================================================================
# CALLBACK: custom_install — build package with maturin
# =============================================================================
custom_install() {
    log_info "Building package with maturin..."
    python -m pip install --upgrade pip maturin
    maturin build --release
}

# =============================================================================
# CALLBACK: pre_test — set Rust toolchain and install test-time build deps
# =============================================================================
pre_test() {
    log_info "Setting Rust ${RUST_VERSION} as default for test environment..."
    rustup default ${RUST_VERSION}

    log_info "Installing maturin in test environment..."
    python -m pip install --upgrade pip setuptools wheel maturin
}

# =============================================================================
# CALLBACK: custom_test_command — run tests with pytest
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies..."
    python -m pip install msgpack pydantic numpy python-dateutil pytz

    # Uninstall plugins that crash during entrypoint loading before -p flags are processed
    python -m pip uninstall -y pytest-cov pytest-xdist pytest-codspeed 2>/dev/null

    log_info "Running pytest..."
    python -m pytest tests/ -o "addopts=" --disable-warnings -v
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"