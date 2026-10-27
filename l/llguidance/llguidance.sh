#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : llguidance
# Version       : v0.7.19
# Source repo   : https://github.com/microsoft/llguidance
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod.K1 <Vinod.K1@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - llguidance is a Rust library with Python bindings via maturin/PyO3
#   - Container environment provides: rust/cargo, gcc/g++
#   - Repository is pre-cloned with full history for version flexibility
#   - Tests run via pytest directly; tox is avoided because tox re-invokes
#     the maturin build backend inside an isolated .pkg venv where rustup
#     has no default toolchain configured, causing a hard failure.
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="llguidance"
PACKAGE_VERSION="${1:-v0.7.19}"
PACKAGE_URL="https://github.com/microsoft/llguidance"
RUST_VERSION="stable"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building llguidance
# Note: rust/cargo, gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git openssl-devel python3-devel python3-pip"
DEB_DEP_PKGS="git libssl-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git libopenssl-devel python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_build
# Install maturin for Rust-Python binding build
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing maturin for Rust-Python binding build..."
    pip install maturin setuptools
}
# =============================================================================
# CALLBACK: pre_test
# Runs inside .venv-test before pip install . compiles the Rust extension.
# =============================================================================
pre_test() {
    log_info "Installing maturin and setuptools in test environment..."
    pip install "maturin<2.0,>=1.0" setuptools
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests via tox (as per legacy script)
# =============================================================================
custom_test_command() {
log_info "Installing tox for testing..."
    python -m pip install tox

    log_info "Creating dynamic tox.ini to pass Rust/Cargo environment variables..."
    cat > tox.ini << 'EOF'
[tox]
envlist = py3

[testenv]
passenv =
    HOME
    PATH
    CARGO_HOME
    RUSTUP_HOME
    LD_LIBRARY_PATH
    LDFLAGS

[testenv:.pkg]
passenv =
    HOME
    PATH
    CARGO_HOME
    RUSTUP_HOME
    LD_LIBRARY_PATH
    LDFLAGS
EOF

    log_info "Running tox tests..."
    export TOX_TESTENV_PASSENV="HOME CARGO_HOME RUSTUP_HOME PATH"
    python -m tox -e py3
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
