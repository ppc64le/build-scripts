#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cblosc
# Version       : v1.21.6
# Source repo   : https://github.com/Blosc/c-blosc
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - High performance compressor/shuffler library
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cblosc"
PACKAGE_VERSION="${1:-v1.21.6}"
PACKAGE_URL="https://github.com/Blosc/c-blosc"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="cblosc"

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
    echo 'export CMAKE_PREFIX_PATH="${CBLOSC_PREFIX}:${CMAKE_PREFIX_PATH:-}"' >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="cmake"
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DPREFER_EXTERNAL_ZLIB=OFF -DPREFER_EXTERNAL_LZ4=OFF -DPREFER_EXTERNAL_ZSTD=OFF -DPREFER_EXTERNAL_SNAPPY=OFF"
LICENSE_SPDX="BSD-3-Clause"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
