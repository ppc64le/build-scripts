#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : msgpack-python
# Version       : v1.1.1
# Source repo   : https://github.com/msgpack/msgpack-python
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - msgpack-python has Cython extensions that require pre-generation
#   - Container environment provides: gcc/g++
#   - Repository is pre-cloned with full history for version flexibility
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="msgpack-python"
PACKAGE_VERSION="${1:-v1.1.1}"
PACKAGE_URL="https://github.com/msgpack/msgpack-python"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building msgpack-python
# Note: gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git python3-devel python3-pip"

# Override default setuptools version constraint
# msgpack-python v1.1.1 requires setuptools>=75.3.0
SETUPTOOLS_VERSION=">=75.3.0"

# =============================================================================
# CALLBACK: pre_build
# Install cython and generate .c files before python -m build runs
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing cython for extension generation..."
    pip install cython

    log_info "Running cython to generate C extension from _cmsgpack.pyx..."
    if [[ -f "msgpack/_cmsgpack.pyx" ]]; then
        if ! cython msgpack/_cmsgpack.pyx; then
            log_error "Failed to cythonize msgpack/_cmsgpack.pyx"
            return 1
        fi
        log_info "Generated msgpack/_cmsgpack.c successfully"
    else
        log_warn "msgpack/_cmsgpack.pyx not found - build may use fallback"
    fi
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
