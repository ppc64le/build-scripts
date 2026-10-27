#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cutadapt
# Version       : v5.1
# Source repo   : https://github.com/marcelm/cutadapt
# Tested on     : UBI:9.6
# Language      : Python (with Cython extensions)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cutadapt"
PACKAGE_VERSION="${1:-v5.1}"
PACKAGE_URL="https://github.com/marcelm/cutadapt"

SETUPTOOLS_VERSION=">=79"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building cutadapt
# Note: gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip zlib-devel"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv zlib1g-dev"
SLES_DEP_PKGS="git python3-devel python3-pip zlib-devel"

# =============================================================================
# CALLBACK: pre_build
# Install cython and build dependencies before python -m build runs
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing build dependencies for cutadapt..."
    # cython needed for .pyx compilation
    # setuptools_scm needed for version detection from git tags
    # dnaio is a required dependency for cutadapt
    python -m pip install cython setuptools_scm dnaio
}

# =============================================================================
# CALLBACK: pre_test
# Install build dependencies in the test venv before tests run
# Note: This runs INSIDE the test venv, so build deps must be reinstalled
# =============================================================================
pre_test() {
    log_info "Installing build dependencies in test environment"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cython setuptools_scm dnaio
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests with test dependencies installed
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies..."

    # Install test requirements
    python -m pip install pytest-timeout pytest-mock

    # Ensure we have a working pytest
    python -m pip install --upgrade "pytest>=7.0"

    log_info "Running pytest..."
    # Deselect test_process_substitution: it feeds input via /dev/fd/<n>
    # process substitution across multiprocessing workers, which is not
    # accessible in chroot/container build environments (not a cutadapt bug).
    python -m pytest --disable-warnings --deselect tests/test_commandline.py::test_process_substitution
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"