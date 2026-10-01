#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : backports.functools_lru_cache
# Version       : v2.0.0
# Source repo   : https://github.com/jaraco/backports.functools_lru_cache
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="backports.functools_lru_cache"
PACKAGE_VERSION="${1:-v2.0.0}"
PACKAGE_URL="https://github.com/jaraco/backports.functools_lru_cache"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Pure Python — skip compilation stages
NOARCH="true"

# =============================================================================
# CALLBACK: pre_clone — set SETUPTOOLS_SCM_PRETEND_VERSION so the SCM version
# detection in setup.cfg/pyproject.toml resolves to the correct release version
# =============================================================================
pre_clone() {
    log_info "Setting SETUPTOOLS_SCM_PRETEND_VERSION to ${PACKAGE_VERSION#v}"
    export SETUPTOOLS_SCM_PRETEND_VERSION="${PACKAGE_VERSION#v}"
}

# =============================================================================
# CALLBACK: post_clone — install ruff and auto-fix formatting issues that
# caused test failures in the original v1 script before the build runs
# =============================================================================
post_clone() {
    log_info "Installing ruff and auto-fixing formatting issues"
    python -m pip install --upgrade ruff
    ruff format .
}

# =============================================================================
# CALLBACK: pre_test — ensure build backend is available in the test venv
# =============================================================================
pre_test() {
    log_info "Installing setuptools, wheel, and pip into test venv"
    python -m pip install --upgrade pip setuptools wheel
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"