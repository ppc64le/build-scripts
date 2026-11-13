#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : xsimd
# Version       : 13.0.0
# Source repo   : https://github.com/xtensor-stack/xsimd
# Tested on     : UBI:9.6
# Language      : C++ (header-only)
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="xsimd"
PACKAGE_VERSION="${1:-13.0.0}"
PACKAGE_URL="https://github.com/xtensor-stack/xsimd"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="xsimd"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git cmake make"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build Configuration
# =============================================================================
# xsimd >= 14 installs xsimdConfig.cmake and xsimd.pc under share/ (DATADIR),
# while 13.x used lib64/.  The artifact cleanup step deletes share/, which would
# leave no CMake package config and break Arrow's find_package(xsimd).  Pointing
# DATADIR at lib64 gives lib64/cmake/xsimd and lib64/pkgconfig for every version
# (13.x does not use DATADIR, so it is unaffected).
CMAKE_OPTS="-DBUILD_TESTS=OFF -DCMAKE_INSTALL_DATADIR=lib64"
LICENSE_SPDX="BSD-3-Clause"
SKIP_TESTS="true"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

