#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : crc32c-google
# Version       : 1.1.2
# Source repo   : https://github.com/google/crc32c
# Tested on     : UBI:9.6
# Language      : C++
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Sanket-Kumbhar <Sanket.Kumbhar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="crc32c-google"
PACKAGE_VERSION="${1:-1.1.2}"
PACKAGE_URL="https://github.com/google/crc32c"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="crc32c-google"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_build — Add CMAKE_PREFIX_PATH to env.sh for consumers
# =============================================================================
post_build() {
    log_info "Running post build"
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export CMAKE_PREFIX_PATH=\"\${CRC32C_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=ON -DCRC32C_BUILD_TESTS=OFF -DCRC32C_BUILD_BENCHMARKS=OFF -DCRC32C_USE_GLOG=OFF"
LICENSE_SPDX="BSD-3-Clause"
SKIP_TESTS=true

# =============================================================================
# Execute template
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

