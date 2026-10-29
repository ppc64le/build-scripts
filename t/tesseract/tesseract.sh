#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tesseract
# Version       : 5.5.1
# Source repo   : https://github.com/tesseract-ocr/tesseract
# Tested on     : UBI:9.6
# Language      : C++
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tesseract"
PACKAGE_VERSION="${1:-5.5.1}"
PACKAGE_URL="https://github.com/tesseract-ocr/tesseract"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="tesseract"
BUILD_DEPS="${BUILD_DEPS:-leptonica:1.85.0}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
# libtiff/libjpeg/libpng/zlib are shared-library deps of the leptonica artifact;
# they must be present here so tesseract can link against libleptonica.so.
RH_DEP_PKGS="git cmake make zlib-devel libjpeg-turbo-devel libpng-devel libtiff-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build Configuration
# CMAKE_INSTALL_RPATH_USE_LINK_PATH records the leptonica artifact lib dir in
# libtesseract's RPATH so it resolves without extra LD_LIBRARY_PATH entries.
# =============================================================================
BUILD_SYSTEM="cmake"
CMAKE_OPTS="-DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON -DOPENMP_BUILD=OFF -DBUILD_TRAINING_TOOLS=OFF"
LICENSE_SPDX="Apache-2.0"
SKIP_TESTS=true  # upstream tests need googletest and tessdata, which the artifact build does not provide

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

