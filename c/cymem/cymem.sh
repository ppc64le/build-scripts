#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cymem
# Version       : v2.0.7
# Source repo   : https://github.com/explosion/cymem
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cymem"
PACKAGE_VERSION="${1:-v2.0.7}"
PACKAGE_URL="https://github.com/explosion/cymem"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel sudo wget"
DEB_DEP_PKGS="cmake git make python3 python3-dev python3-pip python3-venv gcc wget sudo"
SLES_DEP_PKGS="cmake git make python3 python3-devel gcc wget sudo"

# =============================================================================
# CALLBACK: pre_build
# Install Cython inside the build venv before building
# =============================================================================
pre_build() {
    log_info "Installing Cython (required for cymem C extensions)..."
    python -m pip install cython
}

# =============================================================================
# CALLBACK: pre_test
# Install build backend deps into the test venv so pip can build cymem from
# source (avoids "Cannot import 'setuptools.build_meta'" BackendUnavailable)
# =============================================================================
pre_test() {
    log_info "Installing build backend dependencies into test venv..."
    python -m pip install --upgrade pip setuptools wheel cython
}

# =============================================================================
# CALLBACK: custom_test_command
# Use --import-mode=importlib so pytest resolves imports from the installed
# package instead of the source tree (avoids cymem.cymem path shadowing error)
# =============================================================================
custom_test_command() {
    log_info "Running cymem tests..."
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --pyargs cymem
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"