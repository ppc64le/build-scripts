#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : impit
# Version       : py-0.13.1
# Source repo   : https://github.com/apify/impit
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham.Garud@ibm.com
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="impit"
PACKAGE_VERSION="${1:-py-0.13.1}"
PACKAGE_URL="https://github.com/apify/impit"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make openssl-devel python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — update Rust toolchain and install maturin build dependency
# =============================================================================
pre_build() {
    log_info "Updating Rust toolchain to stable..."
    rustup default stable
    rustup update stable

    log_info "Installing maturin build dependency"
    python -m pip install --upgrade pip setuptools wheel maturin
}

# =============================================================================
# CALLBACK: post_clone — navigate to Python bindings subdirectory and patch Cargo.toml
# =============================================================================
post_clone() {
    log_info "Changing to Python bindings directory: impit-python/"
    cd impit-python/

    # Remove the `auto-initialize` pyo3 feature — it requires a shared libpython.so
    # which is not shipped by UBI/RHEL. The `extension-module` feature is sufficient
    # for building a cdylib Python extension.
    log_info "Patching Cargo.toml: removing pyo3 auto-initialize feature"
    sed -i 's/pyo3 = { version = "0.29", features = \["extension-module", "auto-initialize", "either"\] }/pyo3 = { version = "0.29", features = ["extension-module", "either"] }/' Cargo.toml
}

# =============================================================================
# CALLBACK: custom_install — build impit wheel with maturin and install it
# =============================================================================
custom_install() {
    log_info "Building wheel with maturin..."
    maturin build --release

    log_info "Installing built wheel..."
    local wheel
    # maturin resolves the Cargo workspace root (repo root), so the wheel lands
    # one level up from impit-python/ at ../target/wheels/
    wheel=$(find ../target/wheels/ -name "*.whl" | head -1)
    if [[ -z "$wheel" ]]; then
        log_error "No built wheel found under ../target/wheels/"
        false
    fi
    python -m pip install "$wheel"

    log_info "impit installed successfully"
}

# =============================================================================
# CALLBACK: pre_test — ensure Rust toolchain is active and install test deps
# =============================================================================
pre_test() {
    log_info "Updating Rust toolchain to stable for test environment..."
    rustup default stable

    log_info "Installing build backend and test dependencies..."
    python -m pip install --upgrade pip setuptools wheel maturin
    python -m pip install pytest-asyncio pproxy
    python -m pip uninstall -y pytest-cov pytest-xdist 2>/dev/null
}

# =============================================================================
# CALLBACK: custom_test_command — run impit import and functional tests
# =============================================================================
custom_test_command() {

    log_info "Running pytest on impit test suite..."
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        test/ \
        --deselect=test/async_client_test.py \
        --deselect=test/basic_client_test.py \
        --deselect=test/no_client_test.py
        # async_client_test, basic_client_test: require live HTTP endpoints
        # no_client_test: starts real socket servers, not suitable for CI
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
