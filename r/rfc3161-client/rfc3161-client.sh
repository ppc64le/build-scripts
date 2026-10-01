#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : rfc3161-client
# Version          : v1.0.6
# Source repo      : https://github.com/trailofbits/rfc3161-client
# Tested on        : UBI:9.6
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2.0 or later
# Maintainer       : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
#
# ----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="rfc3161-client"
PACKAGE_VERSION="${1:-v1.0.6}"
PACKAGE_URL="https://github.com/trailofbits/rfc3161-client"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ openssl-devel python3-devel"
DEB_DEP_PKGS="gcc g++ libssl-dev python3-dev"
SLES_DEP_PKGS="gcc gcc-c++ libopenssl-devel python3-devel"


# =============================================================================
# CALLBACK: pre_clone — source Rust env and export OpenSSL vars for entire build
# The Rust/cargo environment must be on PATH before pip tries to compile maturin
# from source (no ppc64le pre-built wheel). OpenSSL vars must be set before the
# venv is created so they are visible to both the build and test phases.
# =============================================================================
pre_clone() {
    log_info "Configuring OpenSSL for Rust build..."
    export OPENSSL_DIR=/usr
    export OPENSSL_LIB_DIR=/usr/lib64
    export OPENSSL_INCLUDE_DIR=/usr/include
    export OPENSSL_NO_VENDOR=1
}

# =============================================================================
# CALLBACK: pre_build — install maturin build backend into build venv
# maturin has no ppc64le pre-built wheel; pip compiles it from source using
# the cargo toolchain sourced above. Must also be installed in pre_test since
# the test venv is a fresh, isolated environment that does not inherit from
# .venv-build.
# =============================================================================
pre_build() {
    log_info "Installing maturin build backend..."
    python -m pip install "maturin>=1.7,<2.0"
}

# =============================================================================
# CALLBACK: pre_test — install maturin into test venv
# The test venv does NOT inherit from .venv-build; maturin must be reinstalled
# here so that pip install --no-build-isolation can invoke the maturin backend.
# =============================================================================
pre_test() {
    log_info "Installing maturin build backend into test environment..."
    python -m pip install "maturin>=1.7,<2.0"
    log_info "Installing test dependencies..."
    python -m pip install pretend
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
