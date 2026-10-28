#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyephem
# Version       : 4.2
# Source repo   : https://github.com/brandon-rhodes/pyephem
# Tested on     : UBI:9.6
# Language      : Python, C
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyephem"
PACKAGE_VERSION="${1:-4.2}"
PACKAGE_URL="https://github.com/brandon-rhodes/pyephem"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building pyephem C extensions
# Note: gcc/g++ are provided by the container but listed for clarity
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip gcc gcc-c++"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test
# Ensure test environment has latest build tools before running tests
# =============================================================================
pre_test() {
    log_info "Upgrading pip and build tools in test environment..."
    python -m pip install --upgrade pip setuptools wheel
}

# =============================================================================
# CALLBACK: custom_test_command
# pyephem uses unittest, not pytest - override default test behavior
# =============================================================================
custom_test_command() {
    log_info "Running pyephem unittest test suite..."

    # Compile the C extension binaries locally in the source tree
    python setup.py build_ext -i

    # pyephem uses unittest discover in the ephem directory
    # This is different from the default pytest-based testing
    python -m unittest discover ephem
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"