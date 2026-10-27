#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : xattr
# Version       : v1.1.4
# Source repo   : https://github.com/xattr/xattr
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Manya Rusiya <Manya.Rusiya@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="xattr"
PACKAGE_VERSION="${1:-v1.1.4}"
PACKAGE_URL="https://github.com/xattr/xattr"

RH_DEP_PKGS="git gcc gcc-c++ libffi-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""


# =============================================================================
# CALLBACK: post_clone — read setuptools version from pyproject.toml
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
# CALLBACK: pre_build
# =============================================================================
pre_build() {
    log_info "Installing build dependencies: cffi"
    python -m pip install --upgrade "cffi>=1.16.0"
}

# =============================================================================
# CALLBACK: pre_test
# =============================================================================
pre_test() {
    log_info "Installing test dependencies: pytest"
    python -m pip install pytest
}

# =============================================================================
# CALLBACK: custom_test_command
# =============================================================================
custom_test_command() {
    log_info "Running custom tests"
    python -I -m pytest --import-mode=importlib -o "addopts="
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
