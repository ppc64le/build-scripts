#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : patroni
# Version       : v4.0.5
# Source repo   : https://github.com/zalando/patroni
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: patroni_ubi_9.3.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="patroni"
PACKAGE_VERSION="${1:-v4.0.5}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://github.com/zalando/patroni"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git make openssl openssl-devel postgresql python3 python3-devel python3-pip python3-psycopg2 wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr

# Custom test command (extracted from original script)
custom_test_command() {
    # TODO: Review and update test commands
    pip install flake8 pytest pytest-cov coverage cython
}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# PACKAGE_DIR=patroni
# CURRENT_DIR=${PWD}
# export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
# export PATH=$GCC_TOOLSET_PATH/bin:$PATH
# curl https://sh.rustup.rs -sSf | sh -s -- -y
# source "$HOME/.cargo/env"  # Update environment variables to use Rust
# pip install --upgrade wheel pip setuptools
# pip install flake8 pytest pytest-cov coverage cython
# python3 .github/workflows/install_deps.py
# pip install -r requirements.txt
# pip install -r requirements.dev.txt

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
