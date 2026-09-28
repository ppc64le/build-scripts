#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : openjpeg
# Version       : v2.5.3
# Source repo   : https://github.com/uclouvain/openjpeg
# Tested on     : UBI 9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts@ibm.com>
#
# Notes:
#   - JPEG 2000 codec library
#   - Simple cmake build, no special dependencies
#   - Provides artifact for docling and other packages
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="openjpeg"
PACKAGE_VERSION="${1:-v2.5.3}"
PACKAGE_URL="https://github.com/uclouvain/openjpeg"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="openjpeg"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make zlib-devel libpng-devel libtiff-devel lcms2-devel libwebp-devel libzstd-devel jbigkit-devel"
DEB_DEP_PKGS="git gcc g++ cmake make zlib1g-dev libpng-dev libtiff-dev liblcms2-dev"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make zlib-devel libpng-devel libtiff-devel liblcms2-devel"

# =============================================================================
# CALLBACK: post_build - Add CMAKE_PREFIX_PATH to generated env.sh
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export CMAKE_PREFIX_PATH=\"\${OPENJPEG_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# CALLBACK: custom_test_command - Verify openjpeg installation
# =============================================================================
custom_test_command() {
    log_info "Verifying openjpeg installation..."

    if ! source_artifact openjpeg "${ARTIFACT_VERSION}"; then
        log_error "openjpeg artifact not found"
        return 1
    fi

    # Check binaries exist
    if [[ -x "${OPENJPEG_PREFIX}/bin/opj_decompress" ]]; then
        log_info "opj_decompress found"
        "${OPENJPEG_PREFIX}/bin/opj_decompress" -h 2>&1 | head -3 || true
    fi

    # Check library exists
    if [[ -f "${OPENJPEG_PREFIX}/lib/libopenjp2.so" ]]; then
        log_info "libopenjp2.so found"
    fi

    log_info "openjpeg verification complete"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="cmake"
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DBUILD_STATIC_LIBS=OFF -DBUILD_CODEC=ON -DBUILD_TESTING=OFF"
LICENSE_SPDX="BSD-2-Clause"
SKIP_TESTS=false

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
