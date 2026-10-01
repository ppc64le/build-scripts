#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : frozenlist
# Version       : v1.3.3
# Source repo   : https://github.com/aio-libs/frozenlist
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - frozenlist has Cython extensions that need to be compiled
#   - Python 3.13+ requires a patch for test compatibility
#   - Container environment provides: gcc/g++, python
# ----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="frozenlist"
PACKAGE_VERSION="${1:-v1.3.3}"
PACKAGE_URL="https://github.com/aio-libs/frozenlist"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building frozenlist
# Note: gcc/g++ are provided by the container, but -devel packages are needed
# =============================================================================
RH_DEP_PKGS="git openssl-devel python3-devel python3-pip"
DEB_DEP_PKGS="git libssl-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git libopenssl-devel python3-devel python3-pip"

# =============================================================================
# CALLBACK: post_clone
# Apply Python 3.13+ compatibility patch for tests
# =============================================================================
post_clone() {
    log_info "Applying Python 3.13+ compatibility patch for tests..."
    # Python 3.13 adds __static_attributes__ and __firstlineno__ to class dicts
    # These need to be skipped in the frozenlist tests
    if [[ -f "tests/test_frozenlist.py" ]]; then
        sed -i 's/SKIP_METHODS = {/SKIP_METHODS = {\n        "__static_attributes__",\n        "__firstlineno__",/' tests/test_frozenlist.py
        log_info "Applied Python 3.13+ compatibility patch"
    fi
}

# =============================================================================
# CALLBACK: pre_build
# Install build dependencies including setuptools, cython, and expandvars
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing build dependencies..."
    python -m pip install setuptools wheel cython expandvars

    log_info "Running cython to generate C extensions..."
    if [[ -f "frozenlist/_frozenlist.pyx" ]]; then
        log_info "Cythonizing frozenlist/_frozenlist.pyx..."
        if ! cython frozenlist/_frozenlist.pyx; then
            log_error "Failed to cythonize frozenlist/_frozenlist.pyx"
            return 1
        fi
        log_info "Generated frozenlist/_frozenlist.c"
    else
        log_warn "frozenlist/_frozenlist.pyx not found - build may fail or use pure Python fallback"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests with minimal configuration
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies..."
    python -m pip install pytest

    log_info "Running pytest..."
    # Clear addopts from setup.cfg/pyproject.toml which may include --cov flags
    pytest -o "addopts=" --disable-warnings
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
