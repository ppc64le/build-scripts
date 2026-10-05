#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : httptools
# Version       : v0.6.4
# Source repo   : https://github.com/MagicStack/httptools
# Tested on     : UBI:9.6
# Language      : Python, Cython
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="httptools"
PACKAGE_VERSION="${1:-v0.6.4}"
PACKAGE_URL="https://github.com/MagicStack/httptools"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — Read setuptools version from pyproject.toml
# =============================================================================
post_clone() {
    log_info "Reading setuptools version from pyproject.toml"
    local setuptools_req
    setuptools_req="$(grep -o '"setuptools[><=!][^"]*"' pyproject.toml | head -1 | tr -d '"')"
    if [[ -n "${setuptools_req}" ]]; then
        SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
        SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
        log_info "Using setuptools${SETUPTOOLS_VERSION} (from pyproject.toml)"
    else
        log_info "setuptools not found in pyproject.toml, using template default"
    fi
}

# =============================================================================
# CALLBACK: pre_build — Install cython for C extension compilation
# =============================================================================
pre_build() {
    log_info "Installing cython for extension compilation..."
    python -m pip install cython
}

# =============================================================================
# CALLBACK: pre_test — Install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."
    python -m pip install hypothesis
}

# =============================================================================
# CALLBACK: custom_test_command — Run httptools pytest suite
# =============================================================================
custom_test_command() {
    log_info "Running httptools tests..."
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings 
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
