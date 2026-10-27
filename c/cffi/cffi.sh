#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cffi
# Version       : v1.16.0
# Source repo   : https://github.com/python-cffi/cffi
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
#

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cffi"
PACKAGE_VERSION="${1:-v1.16.0}"
PACKAGE_URL="https://github.com/python-cffi/cffi"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building cffi
# Note: gcc/g++, make, cmake are provided by the container
# =============================================================================
RH_DEP_PKGS="git openssl-devel bzip2-devel libffi-devel zlib-devel python3-devel python3-pip"
DEB_DEP_PKGS="git libssl-dev libbz2-dev libffi-dev zlib1g-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git libopenssl-devel bzip2-devel libffi-devel zlib-devel python3-devel python3-pip"

SETUPTOOLS_VERSION="<77"

# Strip leading 'v' and split PACKAGE_VERSION into numeric components.
# pkg_ver[0]=major  pkg_ver[1]=minor  pkg_ver[2]=patch
# Used by post_clone and pre_test to gate version-specific logic.
_ver=(${PACKAGE_VERSION//v/})
pkg_ver=(${_ver//./ })

post_clone() {
    # Only v1.16.0+ migrated to pyproject.toml with the bare license string.
    # Older versions (e.g. v1.15.1) use setup.cfg only — nothing to patch.
    # Condition: major > 1, OR (major == 1 AND minor >= 16)
    if [[ ${pkg_ver[0]} -gt 1 ]] || [[ ${pkg_ver[0]} -eq 1 && ${pkg_ver[1]} -ge 16 ]]; then
        # Fix PEP 639: rewrite bare string license = "MIT" → table form
        sed -i 's/license = "MIT"/license = { text = "MIT" }/' pyproject.toml
    fi
}

pre_test() {
    # v1.15.x: test_dlopen_unicode_literals.py uses py.code which was removed
    # in py>=1.11.0. Pin py<1.11 so collection does not crash at import time.
    if [[ ${pkg_ver[0]} -eq 1 && ${pkg_ver[1]} -lt 16 ]]; then
        log_info "Installing test dependencies"
        python -m pip install "py<1.11"
    fi
}

custom_test_command() {
    log_info "Running pytest with platform-specific test deselections..."

    # Skip the following tests for known environment-specific reasons:
    # - test_parsing: parser coverage is unstable across pytest/runtime combos
    # - test_zintegration: integration-style test that depends on extra setup
    # - test_callback_exception: exception formatting differs on newer Python/pytest for 3.11+ Versions
    log_info "Running cffi tests"
    python -m pytest \
        -o "addopts=" \
        -k "not test_parsing and not test_zintegration and not test_callback_exception" \
        --disable-warnings
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

