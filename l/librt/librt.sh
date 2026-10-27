#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : librt
# Version       : main
# Source repo   : https://github.com/mypyc/librt
# Tested on     : UBI:9.6
# Language      : Python, C
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="librt"
PACKAGE_VERSION="${1:-v0.8.1}"
PACKAGE_URL="https://github.com/mypyc/librt"

# Override default setuptools version - librt requires setuptools>=77.0.3
SETUPTOOLS_VERSION=">=77.0.3"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building librt
# Note: Requires C compiler (GCC) and Python development headers
# =============================================================================
RH_DEP_PKGS="git wget gcc make python3-devel python3-pip"

DEB_DEP_PKGS="git wget build-essential python3-dev python3-pip python3-venv"

SLES_DEP_PKGS="git wget gcc gcc-c++ make python3-devel python3-pip"

# =============================================================================
# CALLBACK: post_clone
# Sync files from lib-rt directory to root (crucial step for librt)
# =============================================================================
post_clone() {
    log_info "Reading setuptools version from pyproject.toml"
    local setuptools_req
        setuptools_req="$(grep -oE '"setuptools[[:space:]]*[><=!][^"]*"' pyproject.toml | head -1 | tr -d '"')"

    if [[ -n "${setuptools_req}" ]]; then
        SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
        SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
        log_info "Using setuptools${SETUPTOOLS_VERSION} (from pyproject.toml)"
    else
        log_info "setuptools not found in pyproject.toml, using template default"
    fi

    log_info "Syncing lib-rt files to root directory (required for librt)..."
    
    if [[ -d "lib-rt" ]]; then
        # Copy all files from lib-rt to current directory
        cp -r lib-rt/* .
        log_info "Successfully synced lib-rt files"
    else
        log_error "lib-rt directory not found!"
        return 1
    fi
}

# =============================================================================
# CALLBACK: custom_test_command
# Run smoke tests to verify the build
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies..."
    
    # Install pytest and mypy-extensions
    pip install pytest mypy-extensions
    
    # Ensure we have a working pytest
    pip install --upgrade "pytest>=7.0"
    
    log_info "Running smoke tests..."
    
    # Run smoke tests if available
    if [[ -f "smoke_tests.py" ]]; then
        # Override addopts to avoid any config issues
        python -m pytest \
            -o "addopts=" \
            smoke_tests.py \
            -v
    else
        # Verify installation
        log_info "Verifying librt installation..."
        python -c "import librt.base64; import librt.internal; import librt.strings; import librt.time; import librt.vecs; print('All librt modules imported successfully')"
    fi
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
