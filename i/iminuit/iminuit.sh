#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : iminuit
# Version       : v2.31.1
# Source repo   : https://github.com/iminuit/iminuit
# Tested on     : UBI:9.3
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
#   - iminuit is a Python interface to the MINUIT2 C++ library
#   - Uses scikit-build-core + pybind11 for building C++ extensions
#   - Requires cmake for building the MINUIT2 submodule
#   - Container environment provides: gcc/g++, cmake
#   - Repository is pre-cloned with full history for version flexibility
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="iminuit"
PACKAGE_VERSION="${1:-v2.31.1}"
PACKAGE_URL="https://github.com/iminuit/iminuit"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building iminuit
# Note: gcc/g++, cmake are provided by the container
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip cmake"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv cmake"
SLES_DEP_PKGS="git python3-devel python3-pip cmake"

# =============================================================================
# CALLBACK: post_clone
# Initialize submodules after checkout - MINUIT2 C++ source is a submodule
# =============================================================================
post_clone() {
    log_info "Initializing submodules (MINUIT2 C++ library)..."
    git submodule update --init --recursive
}

# =============================================================================
# CALLBACK: pre_build
# Install build dependencies that scikit-build-core needs
# =============================================================================
pre_build() {
    log_info "Installing scikit-build-core, pybind11, and ninja for build..."
    python -m pip install scikit-build-core pybind11 ninja
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests with appropriate configuration
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies..."

    # Install test requirements
    pip install pytest numpy || true

    # iminuit tests are straightforward - run with standard pytest
    # Disable strict markers since pyproject.toml has xfail_strict=true
    # which can cause XPASS failures on different platforms
    log_info "Running pytest..."
    pytest \
        -o "addopts=" \
        -o "xfail_strict=false" \
        --disable-warnings
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
