#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : greenlet
# Version       : 3.0.1
# Source repo   : https://github.com/python-greenlet/greenlet
# Tested on     : UBI:9.6
# Language      : C++, Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="greenlet"
PACKAGE_VERSION="${1:-3.0.1}"
PACKAGE_URL="https://github.com/python-greenlet/greenlet"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building greenlet
# Note: gcc/g++ are provided by the container but we include them for safety
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip openssl-devel"
DEB_DEP_PKGS="git gcc g++ python3-dev python3-pip python3-venv libssl-dev"
SLES_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip libopenssl-devel"

# For version 2.0.1, force using GCC 11 (standard /usr/bin/gcc) instead of GCC 13
if [[ "$PACKAGE_VERSION" == "2.0.1" ]]; then
    export CC="/usr/bin/gcc"
    export CXX="/usr/bin/g++"
fi

# =============================================================================
# CALLBACK: pre_build
# Install dev requirements before building
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing development requirements..."
    if [[ -f "dev-requirements.txt" ]]; then
        python -m pip install -r dev-requirements.txt 
    fi
}
# =============================================================================
# CALLBACK: pre_test
# Install test dependencies before running tests
# Note: This runs INSIDE .venv-test, so pip install works correctly
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."

    # Install setuptools and test extras in editable mode
    python -m pip install setuptools -e ".[test]"
}

# =============================================================================
# CALLBACK: custom_test_command
# greenlet uses unittest, not pytest
# =============================================================================
custom_test_command() {
    log_info "Running unittest test suite..."

    # greenlet uses unittest for testing
    python -m unittest discover -v greenlet.tests
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
