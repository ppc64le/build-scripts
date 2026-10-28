#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : oneTBB
# Version       : v2021.13.0
# Source repo   : https://github.com/oneapi-src/oneTBB
# Tested on     : UBI:9.3
# Language      : C++
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 1 artifact provider (depends on hwloc)
#   - Intel Threading Building Blocks (now oneAPI TBB)
#   - High-level task-based parallelism library
#   - Required by many ML/scientific packages (numpy, scipy with threading)
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="oneTBB"
PACKAGE_VERSION="${1:-v2021.13.0}"
PACKAGE_URL="https://github.com/oneapi-src/oneTBB"

# =============================================================================
# Artifact Declaration (Tier 1 - depends on hwloc)
# =============================================================================
PROVIDES_ARTIFACT="onetbb"
BUILD_DEPS="hwloc"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make"
DEB_DEP_PKGS="git gcc g++ cmake make"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make"

# =============================================================================
# CALLBACK: custom_install
# Build onetbb and install to artifact directory
# Note: BUILD_DEPS are automatically sourced by base.sh before this runs
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}"
        return 0
    fi

    mkdir -p "${ARTIFACT_DIR}" build
    cd build

    cmake \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DTBB_TEST=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DTBB_FIND_PACKAGE=OFF \
        -DCMAKE_PREFIX_PATH="${HWLOC_PREFIX}" \
        ..

    make -j"$(nproc)"
    make install
    cd ..

    # Use base.sh helpers for standard post-build tasks
    _cleanup_artifact "${ARTIFACT_DIR}"
    cp LICENSE.txt "${ARTIFACT_DIR}/LICENSE"  # Non-standard license filename
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}"
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}" \
        "hwloc"
}

# =============================================================================
# Skip tests for native library build
# =============================================================================
SKIP_TESTS=true
LICENSE_SPDX="Apache-2.0"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
