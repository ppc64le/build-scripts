#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pykrb5
# Version       : v0.5.1
# Source repo   : https://github.com/jborean93/pykrb5
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# Note: Directory is named "krb5" but package is "pykrb5"
# =============================================================================
PACKAGE_NAME="pykrb5"
PACKAGE_VERSION="${1:-v0.5.1}"
PACKAGE_URL="https://github.com/jborean93/pykrb5"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building pykrb5
# Note: gcc/g++ are provided by the container
# krb5-devel provides the Kerberos headers needed for compilation
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip krb5-devel krb5-libs"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv libkrb5-dev libkrb5-3 krb5-kdc"
SLES_DEP_PKGS="git python3-devel python3-pip krb5-devel krb5-server"

# =============================================================================
# CALLBACK: pre_build
# Install cython for building extensions
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing cython for building extensions..."
    python -m pip install cython
}

# =============================================================================
# CALLBACK: pre_test
# Install test dependencies before running tests
# Note: This runs INSIDE .venv-test, so pip install works correctly
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."

    # Install dev requirements if available
    if [[ -f "requirements-dev.txt" ]]; then
        python -m pip install -r requirements-dev.txt 
    fi

    # Ensure we have pytest
    python -m pip install --upgrade "pytest>=7.0" 

    # Remove plugins that may cause issues
    python -m pip uninstall -y pytest-cov pytest-xdist 2>/dev/null
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests for pykrb5
# Note: Many tests require a functioning Kerberos KDC which is not available
# in the build environment. We run available tests and accept limited coverage.
# =============================================================================
custom_test_command() {
    log_info "Running pytest..."

    # Skipping test as it requires functioning Kerberos KDC which is not available
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        -v \
        --ignore=tests/test_ccache.py \
        --ignore=tests/test_changepw.py \
        --ignore=tests/test_context.py \
        --ignore=tests/test_creds.py \
        --ignore=tests/test_kt.py \
        --ignore=tests/test_principal.py \
        --ignore=tests/test_string.py || return $?
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
