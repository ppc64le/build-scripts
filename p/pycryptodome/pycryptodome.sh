#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pycryptodome
# Version       : v3.21.0
# Source repo   : https://github.com/Legrandin/pycryptodome
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pycryptodome"
PACKAGE_VERSION="${1:-v3.21.0}"
PACKAGE_URL="https://github.com/Legrandin/pycryptodome"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install cffi required to build C extensions
# =============================================================================
pre_build() {
    log_info "Installing build dependencies for pycryptodome C extensions"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cffi
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into test venv
# =============================================================================
pre_test() {
    log_info "Installing build backend and mirrored build deps into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cffi
}

# =============================================================================
# CALLBACK: custom_test_command — pycryptodome uses its own internal self-test
# =============================================================================
custom_test_command() {
    log_info "Running pycryptodome internal self-test suite (Crypto.SelfTest)"
    python -m Crypto.SelfTest
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
