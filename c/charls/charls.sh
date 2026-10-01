#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : charls
# Version       : 2.4.2
# Source repo   : https://github.com/team-charls/charls
# Tested on     : UBI:9.6
# Language      : C++
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - JPEG-LS lossless/near-lossless image compression library
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="charls"
PACKAGE_VERSION="${1:-2.4.2}"
PACKAGE_URL="https://github.com/team-charls/charls"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="charls"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make"
DEB_DEP_PKGS="git gcc g++ cmake make"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make"

# =============================================================================
# CALLBACK: post_build - Add CMAKE_PREFIX_PATH to generated env.sh
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export CMAKE_PREFIX_PATH=\"\${CHARLS_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="cmake"
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DCHARLS_BUILD_TESTS=OFF -DBUILD_TESTING=OFF -DCHARLS_BUILD_SAMPLES=OFF -DCHARLS_BUILD_CLI=OFF"
LICENSE_SPDX="BSD-3-Clause"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
