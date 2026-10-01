#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : jenkspy
# Version       : 0.4.1
# Source repo   : https://github.com/mthh/jenkspy
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod.K1 <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="jenkspy"
PACKAGE_VERSION="${1:-0.4.1}"
PACKAGE_URL="https://github.com/mthh/jenkspy"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel gcc gcc-c++"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install Cython and numpy before build
# jenkspy compiles Cython extensions; both must be present before
# python -m build --no-isolation is invoked by the template
# =============================================================================
pre_build() {
    log_info "Installing Cython and numpy build dependencies"
    python -m pip install cython numpy
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into the test venv
# .venv-test is isolated from .venv-build; reinstall build-time deps so
# the compiled extensions can be imported during pytest
# =============================================================================
pre_test() {
    log_info "Installing pip/setuptools/wheel and mirroring build deps into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cython numpy
}

custom_test_command() {
    log_info "Running tests from a neutral directory to avoid source tree shadowing"
    python -I -m pytest --import-mode=importlib tests/ \
        -o "addopts=" \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
