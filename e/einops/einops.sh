#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : einops
# Version       : v0.8.1
# Source repo   : https://github.com/arogozhnikov/einops
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="einops"
PACKAGE_VERSION="${1:-v0.8.1}"
PACKAGE_URL="https://github.com/arogozhnikov/einops"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS="git python3-dev python3-venv"
SLES_DEP_PKGS="git python3-devel"

# =============================================================================
# CALLBACK: pre_test — install test dependencies (numpy, nbformat, nbconvert)
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install numpy nbformat nbconvert
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest excluding notebook tests
# =============================================================================
custom_test_command() {
    # test_notebook requires Jupyter kernel and heavy ML backends (torch/jax/tf) not available on ppc64le CI
    log_info "Running tests (excluding notebook tests)"
    EINOPS_TEST_BACKENDS=numpy python -m pytest \
        --disable-warnings \
        -k "not test_notebook" 
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"