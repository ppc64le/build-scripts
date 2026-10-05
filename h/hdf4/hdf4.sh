#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : hdf4
# Version       : hdf4.3.0
# Source repo   : https://github.com/HDFGroup/hdf4
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="hdf4"
PACKAGE_VERSION="${1:-hdf4.3.0}"
PACKAGE_URL="https://github.com/HDFGroup/hdf4"

# HDF4 tags use the format "hdf4.X.Y" (e.g. hdf4.3.0).
# Normalise bare semver input (e.g. "4.3.0" passed by CI) to the correct tag.
if [[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+ ]]; then
    PACKAGE_VERSION="hdf${PACKAGE_VERSION}"
fi

# =============================================================================
# Artifact Declaration (Tier 0 - no native dependencies)
# =============================================================================
PROVIDES_ARTIFACT="hdf4"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make cmake zlib-devel libjpeg-devel"
DEB_DEP_PKGS="git gcc g++ make cmake zlib1g-dev libjpeg-dev"
SLES_DEP_PKGS="git gcc gcc-c++ make cmake zlib-devel libjpeg-devel"

# =============================================================================
# CALLBACK: post_build - Add CMAKE_PREFIX_PATH to generated env.sh
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export CMAKE_PREFIX_PATH=\"\${HDF4_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# HDF4 repo ships a legacy configure script alongside CMakeLists.txt;
# BUILD_SYSTEM="cmake" prevents base.sh from picking the wrong build system.
# =============================================================================
BUILD_SYSTEM="cmake"
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib \
    -DHDF4_BUILD_FORTRAN=OFF \
    -DHDF4_BUILD_JAVA=OFF \
    -DHDF4_ENABLE_NETCDF=OFF \
    -DHDF4_BUILD_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF"
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
