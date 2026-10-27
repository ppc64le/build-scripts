#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : setools
# Version       : 4.4.4
# Source repo   : https://github.com/SELinuxProject/setools
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="setools"
PACKAGE_VERSION="${1:-4.4.4}"
PACKAGE_URL="https://github.com/SELinuxProject/setools"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make python3-devel libselinux-devel libsepol-devel checkpolicy"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — pin setuptools<82 and compile Cython extension in-place
# =============================================================================
# setup.py uses setup_requires=['setuptools', 'Cython>=0.27'] which calls
# pkg_resources — removed in setuptools>=82, so pin to <82.
# policyrep.pyx must be compiled in-place before pip install runs.
pre_build() {
    log_info "Installing Cython and pinning setuptools<82 for pkg_resources compatibility"
    python -m pip install "setuptools<82" wheel "Cython>=0.27"

    log_info "Pre-compiling policyrep Cython extension in-place"
    python setup.py build_ext --inplace
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into test venv; install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing build backend and test dependencies into test venv"
    python -m pip install --upgrade pip "setuptools<82" wheel
    python -m pip install "Cython>=0.27"
    python -m pip install networkx
}

# =============================================================================
# CALLBACK: custom_test_command — run setools test suite
# =============================================================================
custom_test_command() {
    log_info "Running setools tests"
    python -m pytest \
        -o "addopts=" \
        --import-mode=importlib \
        --disable-warnings \
        tests
}

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="LGPL-2.1-only"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
