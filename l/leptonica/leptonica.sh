#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : leptonica
# Version       : 1.85.0
# Source repo   : https://github.com/DanBloomberg/leptonica
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="leptonica"
PACKAGE_VERSION="${1:-1.85.0}"
PACKAGE_URL="https://github.com/DanBloomberg/leptonica"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="leptonica"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git cmake make zlib-devel libjpeg-turbo-devel libpng-devel libtiff-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_build — install lept.pc and drop its unresolvable Requires
# - cmake installs lept_Release.pc; rename it to lept.pc so pkg-config finds it
# - lept.pc lists libwebp/libwebpmux in Requires, which are not installed; that makes
#   pkg-config fail for tesseract (Requires.private: lept) and tesserocr's setup.py
#   then finds no include/library flags
# =============================================================================
post_build() {
    local ARTIFACT_DIR pc_dir
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    pc_dir="${ARTIFACT_DIR}/lib/pkgconfig"

    log_info "Installing lept.pc and removing unresolvable Requires entries"
    if ls "${pc_dir}/lept_"*.pc >/dev/null 2>&1; then
        mv "${pc_dir}/lept_"*.pc "${pc_dir}/lept.pc"
    fi
    sed -i '/^Requires\(\.private\)\?:/d' "${pc_dir}/lept.pc"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="cmake"
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DENABLE_GIF=OFF -DENABLE_OPENJPEG=OFF"
LICENSE_FILE="leptonica-license.txt"
LICENSE_SPDX="BSD-2-Clause"
SKIP_TESTS="true"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

