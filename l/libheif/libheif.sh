#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : libheif
# Version       : v1.23.0
# Source repo   : https://github.com/strukturag/libheif.git
# Tested on     : UBI:9.6
# Language      : C, C++
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 2 artifact provider (depends on: libde265, libtiff)
#   - ISO/IEC 23008-12:2017 HEIF file format decoder and encoder
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="libheif"
PACKAGE_VERSION="${1:-v1.23.0}"
PACKAGE_URL="https://github.com/strukturag/libheif.git"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="libheif"
BUILD_DEPS="libde265:v1.1.1 libtiff:v4.7.1 x265:4.2"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make libwebp-devel"
DEB_DEP_PKGS="git gcc g++ cmake make libwebp-dev"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make libwebp-devel"

# =============================================================================
# CALLBACK: custom_install
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}"
        return 0
    fi

    # Source dependencies
    if ! source_artifact libde265; then
        log_error "libde265 dependency is missing!"
        return 1
    fi

    if ! source_artifact libtiff; then
        log_error "libtiff dependency is missing!"
        return 1
    fi

    if ! source_artifact x265; then
        log_error "x265 dependency is missing!"
        return 1
    fi

    # Help linker find transitive system dependencies (like libwebp) and artifact libraries
    export LDFLAGS="${LDFLAGS:-} -Wl,-rpath-link,/usr/lib64 -Wl,-rpath-link,/usr/lib -Wl,-rpath-link,${LIBTIFF_PREFIX}/lib -Wl,-rpath-link,${LIBDE265_PREFIX}/lib -Wl,-rpath-link,${X265_PREFIX}/lib"

    mkdir -p "${ARTIFACT_DIR}" build
    cd build

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DWITH_LIBDE265=ON \
        -DWITH_X265=ON \
        -DWITH_AOM_DECODER=OFF \
        -DWITH_AOM_ENCODER=OFF \
        -DWITH_DAV1D=OFF \
        -DWITH_SVTENC=OFF \
        -DWITH_RAV1E=OFF \
        -DBUILD_TESTING=OFF \
        .. || { log_error "CMake configuration failed"; return 1; }

    make -j"$(nproc)" || { log_error "Build failed"; return 1; }
    make install || { log_error "Install failed"; return 1; }
    cd ..

    # Use base.sh helpers for standard post-build tasks
    _cleanup_artifact "${ARTIFACT_DIR}"
    _copy_license "${ARTIFACT_DIR}"
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}"
    
    # Append CMAKE_PREFIX_PATH to the generated env.sh
    echo "export CMAKE_PREFIX_PATH=\"\${LIBHEIF_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"

    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}" \
        "libde265" "libtiff" "x265"
}

# =============================================================================
# Build Configuration
# =============================================================================
SKIP_TESTS=true
LICENSE_SPDX="LGPL-3.0-or-later"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
