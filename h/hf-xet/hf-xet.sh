#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : hf-xet
# Version       : v1.5.0
# Source repo   : https://github.com/huggingface/xet-core
# Tested on     : UBI:9.6
# Language      : Python (Rust/maturin-based)
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod.K1 <Vinod.K1@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - hf-xet is a Rust/Python hybrid package using maturin for build
#   - Source lives in hf_xet subdirectory of xet-core repo
#   - Container environment provides: rust/cargo, gcc
#   - Tests are skipped: no test files exist in the package
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="hf-xet"
PACKAGE_VERSION="${1:-v1.5.0}"
PACKAGE_URL="https://github.com/huggingface/xet-core"

# The repo name differs from package name - clone into xet-core
CLONE_DIR="xet-core"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building hf-xet (Rust extension)
# Note: rust/cargo provided by container environment
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ openssl-devel python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ libssl-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ libopenssl-devel python3-devel python3-pip"

# =============================================================================
# Callback : pre_clone hook for applying patch for needed version
# maturin is a PEP 517 build backend - pip install works with it
# =============================================================================
post_clone() {
    # Apply patch for versions 1.1.0, 1.1.1, and 1.1.2
    if [[ "$PACKAGE_VERSION" =~ 1.1.0 || "$PACKAGE_VERSION" =~ 1.1.1 ]]; then
        log_info "Applying patch for ${PACKAGE_VERSION}..."
        PATCH_FILE="${SCRIPT_DIR}/patches/hf_xet.patch"

        if [[ -f "${PATCH_FILE}" ]]; then
            log_info "Found patch file: ${PATCH_FILE}"
            if ! git apply "${PATCH_FILE}"; then
                log_error "Failed to apply patch: ${PATCH_FILE}"
                return 1
            fi
            log_info "Patch applied successfully"
        else
            log_warn "No patch file found for version ${PACKAGE_VERSION}"
            log_warn "Expected: ${PATCH_FILE}"
        fi
        cp LICENSE hf_xet/
    fi

    # For all versions, dynamically remove "auto-initialize" from Cargo.toml
    # to prevent compilation failure with static Python distributions.
    if [[ -f "hf_xet/Cargo.toml" ]]; then
        log_info "Dynamically removing 'auto-initialize' from hf_xet/Cargo.toml..."
        sed -i 's/"auto-initialize",//g' hf_xet/Cargo.toml
    fi

    # Go to the package directory within the repo for all subsequent stages (build, test, etc.)
    cd hf_xet

    # Create the Python module folder expected by Maturin to bypass python-source checks
    mkdir -p python/hf_xet
    touch python/hf_xet/__init__.py
}

# =============================================================================
# Helper: Install build-system dependencies
# =============================================================================
install_pyproject_dependencies() {
    if [[ -f "pyproject.toml" ]]; then
        log_info "Extracting build-system requirements from pyproject.toml..."
        python -m pip install tomli
        # Install requirements together for proper dependency resolution
        python -c "
import tomli
import subprocess
import sys
with open('pyproject.toml', 'rb') as f:
    requires = tomli.load(f).get('build-system', {}).get('requires', [])
    if requires:
        subprocess.run([sys.executable, '-m', 'pip', 'install'] + requires, check=True)
" || log_warn "Failed to install some build requirements"
    fi
}

# =============================================================================
# CALLBACK: pre_build
# Run pre_build hook for installing dependencies
# =============================================================================
pre_build() {
    log_info "Running pre_build hook for installing dependencies..."
    install_pyproject_dependencies
}

# =============================================================================
# CALLBACK: pre_test
# Run pre_test hook for installing dependencies
# =============================================================================
pre_test() {
    log_info "Running pre_test hook for installing dependencies..."
    install_pyproject_dependencies
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests using pytest in isolated import mode
# =============================================================================
custom_test_command() {
    # Only version above 1.5.0 has tests so adding this check
    if [[ -d "tests" ]]; then
        log_info "Found tests dir, running tests..."
        python -I -m pytest --import-mode=importlib -o "addopts=" -o pythonpath=tests tests/
    else
        log_info "No tests directory found in this version of the package. Skipping tests."
        return 0
    fi
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
