#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : brunsli
# Version       : v0.1
# Source repo   : https://github.com/google/brunsli
# Tested on     : UBI:9.6
# Language      : C++
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="brunsli"
PACKAGE_VERSION="${1:-v0.1}"
PACKAGE_URL="https://github.com/google/brunsli"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="brunsli"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_build - Add CMAKE_PREFIX_PATH to generated env.sh
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export CMAKE_PREFIX_PATH=\"\${BRUNSLI_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib"
LICENSE_SPDX="Apache-2.0"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
