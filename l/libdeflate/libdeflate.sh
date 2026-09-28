#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : libdeflate
# Version       : v1.20
# Source repo   : https://github.com/ebiggers/libdeflate.git
# Tested on     : UBI:9.6
# Language      : C
# Script License: MIT License
# Maintainer    : IBM
#
# Notes:
#   - Highly optimized compressor/decompressor for DEFLATE/ZLIB/GZIP formats
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="libdeflate"
PACKAGE_VERSION="${1:-v1.20}"
PACKAGE_URL="https://github.com/ebiggers/libdeflate.git"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="libdeflate"

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
    echo "export CMAKE_PREFIX_PATH=\"\${LIBDEFLATE_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DLIBDEFLATE_BUILD_SHARED_LIB=ON -DLIBDEFLATE_BUILD_STATIC_LIB=ON"
LICENSE_SPDX="MIT"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
