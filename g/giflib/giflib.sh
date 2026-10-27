#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : giflib
# Version       : 6.1.3
# Source repo   : https://git.code.sf.net/p/giflib/code
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - Library for reading and writing gif images
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="giflib"
PACKAGE_VERSION="${1:-6.1.3}"
# Note: SourceForge (sf.net) is the official host and repository for giflib.
# No official GitHub mirror exists, so we clone from the official SourceForge Git repo.
PACKAGE_URL="https://git.code.sf.net/p/giflib/code"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="giflib"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make"
DEB_DEP_PKGS="git gcc g++ make"
SLES_DEP_PKGS="git gcc gcc-c++ make"

# =============================================================================
# CALLBACK: post_build - Add CMAKE_PREFIX_PATH to generated env.sh
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export CMAKE_PREFIX_PATH=\"\${GIFLIB_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="make"
MAKE_OPTS=""
MAKE_TARGET="libgif.so libgif.a libutil.so libutil.a"
INSTALL_TARGET="install-bin install-include install-lib"
LICENSE_SPDX="MIT"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
