#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : selinux
# Version       : v0.3.0
# Source repo   : https://github.com/pycontribs/selinux
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="selinux"
PACKAGE_VERSION="${1:-v0.3.0}"
PACKAGE_URL="https://github.com/pycontribs/selinux"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"
RUST_VERSION="1.75.0"

# =============================================================================
# CALLBACK: pre_build — install missing build backend requirements and set the Rust toolchain
# =============================================================================
pre_build() {
    log_info "Installing build dependencies"
    python -m pip install "setuptools_scm[toml]>=7.0.0"

    log_info "Setting up Rust toolchain"
    log_info "Installing Rust ${RUST_VERSION} for ${PACKAGE_NAME} ${PACKAGE_VERSION} compatibility"
    rustup install ${RUST_VERSION}
    rustup default ${RUST_VERSION}
}

# =============================================================================
# CALLBACK: pre_test — install package-specific test deps and mirror the Rust toolchain
# =============================================================================
pre_test() {
    log_info "Installing package-specific test dependencies"
    python -m pip install bcrypt

    log_info "Setting Rust ${RUST_VERSION} as default for test environment"
    rustup default ${RUST_VERSION}
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

