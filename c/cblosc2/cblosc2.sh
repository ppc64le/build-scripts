#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cblosc2
# Version       : v3.1.2
# Source repo   : https://github.com/Blosc/c-blosc2
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - Fast, compressed, persistent binary data store library
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cblosc2"
PACKAGE_VERSION="${1:-v3.1.2}"
PACKAGE_URL="https://github.com/Blosc/c-blosc2"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="cblosc2"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make zlib-devel"
DEB_DEP_PKGS="git gcc g++ cmake make"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make"

# =============================================================================
# CALLBACK: post_build - Add CMAKE_PREFIX_PATH to generated env.sh
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo 'export CMAKE_PREFIX_PATH="${CBLOSC2_PREFIX}:${CMAKE_PREFIX_PATH:-}"' >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="cmake"
# CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DBLOSC_DEPENDENCY_MODE=BUNDLED"
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DPREFER_EXTERNAL_ZLIB=ON -DPREFER_EXTERNAL_LZ4=OFF -DPREFER_EXTERNAL_ZSTD=OFF -DPREFER_EXTERNAL_SNAPPY=OFF"
LICENSE_SPDX="BSD-3-Clause"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
