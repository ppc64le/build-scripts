#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : x265
# Version       : 4.2
# Source repo   : https://github.com/Multicorewareinc/x265
# Tested on     : UBI:9.6
# Language      : C, C++
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - H.265/HEVC video encoder library
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="x265"
PACKAGE_VERSION="${1:-4.2}"
PACKAGE_URL="https://github.com/Multicorewareinc/x265"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="x265"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make"
DEB_DEP_PKGS="git gcc g++ cmake make"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make"

# =============================================================================
# CALLBACK: post_clone - Create top-level CMakeLists.txt forwarding to source/
# =============================================================================
post_clone() {
    log_info "Creating top-level forwarding CMakeLists.txt..."
    cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.0)
project(x265_top)
add_subdirectory(source)
EOF
}

# =============================================================================
# CALLBACK: post_build - Add CMAKE_PREFIX_PATH to generated env.sh
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export CMAKE_PREFIX_PATH=\"\${X265_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DENABLE_SHARED=ON -DENABLE_CLI=OFF"
LICENSE_SPDX="GPL-2.0-only"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

