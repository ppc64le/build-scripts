#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pytest-mypy
# Version       : v1.0.1
# Source repo   : https://github.com/realpython/pytest-mypy
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K<Vinod.K1 @ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pytest-mypy"
PACKAGE_VERSION="${1:-v1.0.1}"
PACKAGE_URL="https://github.com/realpython/pytest-mypy"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Behaviour variables
# =============================================================================
NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — install build backend, mirrored build deps, and pytest-xdist
# =============================================================================
pre_test() {
    log_info "Installing build backend, mirrored build deps, and pytest-xdist"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "setuptools-scm>=7.1" pytest-xdist
}

# =============================================================================
# CALLBACK: custom_test_command — deselect test_mypy_encoding_warnings
# =============================================================================
custom_test_command() {
    log_info "Running tests (deselecting test_mypy_encoding_warnings)"
    # mypy 2.3.0 emits 3 encoding warnings instead of expected 2 (upstream issue python/mypy#14603)
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --deselect tests/test_pytest_mypy.py::test_mypy_encoding_warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
