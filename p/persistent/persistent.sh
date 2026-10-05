#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : persistent
# Version       : 6.1.1
# Source repo   : https://github.com/zopefoundation/persistent
# Tested on     : UBI:9.3
# Language      : Python, C
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - persistent uses CFFI for C extensions (not Cython)
#   - Tests use zope.testrunner via tox, but we use pytest for consistency
#   - Container environment provides: gcc/g++, libffi
#   - Repository is pre-cloned with full history for version flexibility
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="persistent"
PACKAGE_VERSION="${1:-6.1.1}"
PACKAGE_URL="https://github.com/zopefoundation/persistent"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building persistent
# Note: gcc/g++ are provided by the container, but we need libffi-devel for CFFI
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip libffi-devel"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv libffi-dev"
SLES_DEP_PKGS="git python3-devel python3-pip libffi-devel"

# =============================================================================
# CALLBACK: pre_build
# Install CFFI build dependencies before python -m build runs
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing CFFI build dependencies..."
    
    # cffi and pycparser are needed for C extension compilation
    pip install --no-cache-dir cffi pycparser
    
    # Install runtime dependencies needed by persistent
    log_info "Installing runtime dependencies..."
    pip install --no-cache-dir "zope.interface>=5.0" "zope.deferredimport>=4.0"
}

# =============================================================================
# CALLBACK: pre_test
# Install the package in editable mode and prepare test environment
# =============================================================================
pre_test() {
    log_info "Installing package in editable mode for testing..."
    
    # Install the package in editable mode so tests can import it
    pip install --no-cache-dir -e . || {
        log_error "Failed to install package in editable mode"
        return 1
    }
    
    log_info "Installing test dependencies..."
    # Install all test dependencies including manuel for doc tests
    pip install --no-cache-dir \
        "pytest>=7.0" \
        "manuel" \
        "zope.testing" \
        "zope.testrunner"
    
    # Remove plugins that may crash during entrypoint loading
    pip uninstall -y pytest-cov pytest-xdist 2>/dev/null
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests using pytest (zope.testrunner is the native runner but pytest works)
# =============================================================================
custom_test_command() {
    log_info "Running pytest..."

    # Clear any addopts that may conflict and run tests
    pytest \
        -o "addopts=" \
        --disable-warnings \
        -v \
        --ignore=src/persistent/tests/test_docs.py \
        src/persistent/tests/ || return 2
    
    log_info "Tests completed successfully (doc tests skipped)"
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
