#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : libclang
# Version       : llvm-14.0.6
# Source repo   : https://github.com/sighingnow/libclang
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Vinod.K1 <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="libclang"
PACKAGE_VERSION="${1:-llvm-14.0.6}"
PACKAGE_URL="https://github.com/sighingnow/libclang"

NOARCH="true"
PYPI_VERSION="${PACKAGE_VERSION#llvm-}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command — smoke import test; no upstream test suite exists
# =============================================================================
custom_test_command() {
    log_info "Running smoke import test for libclang..."
    python -c "import clang.cindex; print('libclang import OK:', clang.cindex.__file__)"
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
