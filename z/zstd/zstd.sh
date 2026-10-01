#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : zstd
# Version       : v1.5.6
# Source repo   : https://github.com/facebook/zstd
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - Zstandard fast compression algorithm by Facebook
#   - Required by many packages needing compression (arrow, imagecodecs, etc.)
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="zstd"
PACKAGE_VERSION="${1:-v1.5.6}"
PACKAGE_URL="https://github.com/facebook/zstd"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="zstd"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make"
DEB_DEP_PKGS="git gcc g++ cmake make"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make"

# =============================================================================
# CALLBACK: pre_clone
# Remove .gitmodules before clone - zstd has a self-referential submodule
# that clones itself into zstd/ and breaks the build
# =============================================================================
pre_clone() {
    # In CI mode, repo is pre-cloned - remove .gitmodules to skip submodule init
    if [[ -f ".gitmodules" ]]; then
        log_info "Removing .gitmodules to skip self-referential submodule"
        rm -f .gitmodules
    fi
}

# =============================================================================
# CALLBACK: post_clone
# Create top-level CMakeLists.txt forwarding to build/cmake/
# =============================================================================
post_clone() {
    log_info "Creating top-level forwarding CMakeLists.txt for zstd..."
    cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.0)
project(zstd_top)
add_subdirectory(build/cmake)
EOF
}

# =============================================================================
# CALLBACK: post_build - Add CMAKE_PREFIX_PATH to generated env.sh
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export CMAKE_PREFIX_PATH=\"\${ZSTD_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="cmake"
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib"
LICENSE_SPDX="BSD-3-Clause"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
