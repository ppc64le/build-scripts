#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : bcrypt
# Version       : 4.2.1
# Source repo   : https://github.com/pyca/bcrypt
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - bcrypt uses Rust extensions via setuptools-rust
#   - Container environment provides: rust/cargo, gcc/g++
#   - Repository is pre-cloned with full history for version flexibility
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="bcrypt"
PACKAGE_VERSION="${1:-4.2.1}"
PACKAGE_URL="https://github.com/pyca/bcrypt"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building bcrypt
# Note: rust/cargo, gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_build
# Install setuptools-rust before building (required for Rust extension)
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing setuptools-rust for Rust extension build..."
    pip install setuptools-rust
    
    # Check if Python version > 3.13 and set PyO3 forward compatibility
    # PyO3 0.23.5 supports up to Python 3.13
    if [[ -n "${LANGUAGE_VERSION:-}" ]]; then
        local lang_ver=(${LANGUAGE_VERSION//./ })
        
        # Check if Python > 3.13
        # Logic: (Major > 3) OR (Major == 3 AND Minor > 13)
        if [[ ${lang_ver[0]} -gt 3 ]] || [[ ${lang_ver[0]} -eq 3 && ${lang_ver[1]} -gt 13 ]]; then
            log_info "Python ${LANGUAGE_VERSION} detected (> 3.13), enabling PyO3 forward compatibility"
            export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
        fi
    fi
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"