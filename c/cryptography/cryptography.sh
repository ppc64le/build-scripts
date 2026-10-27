#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package           : cryptography
# Version           : 48.0.0
# Source repo       : https://github.com/pyca/cryptography
# Tested on         : UBI:9.6
# Language          : Python
# Script License    : Apache License, Version 2.0
# Maintainer        : Md. Shafi Hussain <Md.Shafi.Hussain@ibm.com>
#

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cryptography"
PACKAGE_VERSION="${1:-48.0.0}"
PACKAGE_URL="https://github.com/pyca/cryptography"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building cryptography
# Note: rust/cargo, gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git openssl-devel libffi-devel python3-devel python3-pip redhat-rpm-config pkg-config"
DEB_DEP_PKGS="git libssl-dev libffi-dev python3-dev python3-pip python3-venv pkg-config"
SLES_DEP_PKGS="git libopenssl-devel libffi-devel python3-devel python3-pip pkg-config"

# =============================================================================
# CALLBACK: pre_clone
# Set environment variables before building
# =============================================================================
pre_clone() {
    # SHA1 signatures are disabled by default in newer OpenSSL for security reasons.
    # cryptography's tests verify SHA1 compatibility, so we need to enable it.
    # See: https://github.com/pyca/cryptography/issues/6547
    export OPENSSL_ENABLE_SHA1_SIGNATURES=1
    log_info "Enabled OPENSSL_ENABLE_SHA1_SIGNATURES for RSA SHA1 test compatibility"
}

# =============================================================================
# CALLBACK: post_clone
# Initialize submodules if needed (some versions have them)
# =============================================================================
post_clone() {
    # Some versions have submodules (wycheproof test vectors)
    if [[ -f ".gitmodules" ]]; then
        log_info "Initializing git submodules..."
        git submodule update --init --recursive
    fi
}

# =============================================================================
# CALLBACK: pre_build
# Install build dependencies - cryptography uses Rust via maturin/setuptools-rust
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing build dependencies for cryptography..."
    # setuptools-rust handles the Rust extension compilation
    # cffi is used for the C bindings
    # Pin maturin to a known-good range for RHEL 9 / Python 3.13 compatibility
    pip install setuptools-rust cffi maturin
}

# =============================================================================
# CALLBACK: pre_test
# Install maturin in the test venv so that `pip install --no-build-isolation .`
# can find the maturin build backend (it is NOT inherited from .venv-build).
# Pin maturin to the same range used in pre_build to avoid import failures on
# RHEL 9 caused by native extension ABI mismatches in newer maturin releases.
# =============================================================================
pre_test() {
    log_info "Installing maturin build backend into test environment..."
    pip install maturin setuptools-rust cffi
}

custom_test_command() {
    log_info "Running cryptography tests..."

    pip install uv
    
    log_info "Installing test dependencies for cryptography"

    # Use uv to install the package with test optional dependencies from pyproject.toml
    # uv reads and installs all dependencies defined in [project.optional-dependencies.test]
    log_info "Installing cryptography with test dependencies using uv..."

    uv pip install -e ".[test]" certifi pretend pytest-benchmark

    # Install cryptography_vectors matching the package version
    # Strip 'v' prefix if present
    local version="${PACKAGE_VERSION#v}"
    pip install "cryptography_vectors==${version}" || {
        log_warn "Could not install cryptography_vectors==${version}, trying without version pin"
        pip install cryptography_vectors
    }

    log_info "Running all pytest tests..."

    # Run all tests
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        --maxfail=1
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

