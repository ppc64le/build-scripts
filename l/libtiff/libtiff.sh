#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : libtiff
# Version       : v4.7.1
# Source repo   : https://github.com/libsdl-org/libtiff
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - TIFF library and utilities
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="libtiff"
PACKAGE_VERSION="${1:-v4.7.1}"
PACKAGE_URL="https://github.com/libsdl-org/libtiff"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="libtiff"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make zlib-devel libjpeg-turbo-devel libwebp-devel libzstd-devel xz-devel"
DEB_DEP_PKGS="git gcc g++ cmake make zlib1g-dev libjpeg-dev libwebp-dev libzstd-dev liblzma-dev"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make zlib-devel libjpeg-turbo-devel libwebp-devel libzstd-devel xz-devel"

# =============================================================================
# CALLBACK: post_build - Add CMAKE_PREFIX_PATH to generated env.sh
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export CMAKE_PREFIX_PATH=\"\${LIBTIFF_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="cmake"
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -Dtiff-tests=OFF -Dtiff-docs=OFF"
LICENSE_SPDX="libtiff"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
