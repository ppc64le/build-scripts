#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : lcms2
# Version       : lcms2.16
# Source repo   : https://github.com/mm2/Little-CMS
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2.0 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="lcms2"
PACKAGE_VERSION="${1:-lcms2.16}"
PACKAGE_URL="https://github.com/mm2/Little-CMS"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="lcms2"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make autoconf automake libtool libtiff-devel libjpeg-turbo-devel"
DEB_DEP_PKGS="git gcc g++ make autoconf automake libtool libtiff-dev libjpeg-dev"
SLES_DEP_PKGS="git gcc gcc-c++ make autoconf automake libtool libtiff-devel libjpeg-devel"

# =============================================================================
# CALLBACK: post_build — Add CMAKE_PREFIX_PATH and alias legacy LCMS_PREFIX
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo "export LCMS_PREFIX=\"\${LCMS2_PREFIX}\"" >> "${ARTIFACT_DIR}/env.sh"
    echo "export CMAKE_PREFIX_PATH=\"\${LCMS2_PREFIX}:\${CMAKE_PREFIX_PATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# CALLBACK: pre_build — Set environment variables for build
# =============================================================================
pre_build() {
    export CFLAGS="-O3 -fPIC"
}

# =============================================================================
# Build Configuration
# =============================================================================
CONFIGURE_OPTS="--enable-shared --disable-static"
LICENSE_SPDX="MIT"
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
