#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : msgspec
# Version       : 0.19.0
# Source repo   : https://github.com/jcrist/msgspec
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="msgspec"
PACKAGE_VERSION="${1:-0.19.0}"
PACKAGE_URL="https://github.com/jcrist/msgspec"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git python3-devel python3-pip"

# =============================================================================
# CALLBACK: post_clone — read setuptools version from pyproject.toml
# =============================================================================
post_clone() {
    log_info "Reading setuptools version from pyproject.toml"
    local setuptools_req
    setuptools_req="$(grep -o '"setuptools[><=!][^"]*"' pyproject.toml | head -1 | tr -d '"')"
    if [[ -n "${setuptools_req}" ]]; then
        SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
        SETUPTOOLSVERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
        log_info "Using setuptools${SETUPTOOLS_VERSION} (from pyproject.toml)"
    else
        log_info "setuptools not found in pyproject.toml, using template default"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install build-time dependencies for newer versions
# =============================================================================
pre_build() {
    log_info "Installing build-time dependencies for 0.21.1+"
    python -m pip install "setuptools-scm>=8"
}
# =============================================================================
# CALLBACK: pre_test — install test dependencies
# =============================================================================
pre_test() {
    log_info "running pre test hook"
    if [[ "${PACKAGE_VERSION#v}" == "0.21.1" ]]; then
        python -m pip install attrs PyYAML tomli_w pyright mypy
    else
        python -m pip install attrs PyYAML tomli_w
    fi
}

# =============================================================================
# CALLBACK: custom_test_command
# Use -I flag to prevent importing from source directory (C extensions)
# Skip test_raw_copy_doesnt_leak: memory profiling test that spawns subprocess
# without -I flag, causing import failure (not a functional issue)
# =============================================================================
custom_test_command() {
    log_info "running custom test hook"
    python -I -m pytest \
        -o "addopts=" \
        --deselect=tests/test_raw.py::test_raw_copy_doesnt_leak \
        -v
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
