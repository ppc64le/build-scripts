#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : zlib
# Version       : v1.3.1
# Source repo   : https://github.com/madler/zlib
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="zlib"
PACKAGE_VERSION="${1:-v1.3.1}"
PACKAGE_URL="https://github.com/madler/zlib"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="zlib"
LICENSE_SPDX="Zlib"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc make"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command — run zlib's built-in test suite
# =============================================================================
custom_test_command() {
    log_info "Running zlib test suite via make check"
    make check
}

# =============================================================================
# Execute the build (invokes the base C/C++ template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

