#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : imageio
# Version       : v2.34.1
# Source repo   : https://github.com/imageio/imageio
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="imageio"
PACKAGE_VERSION="${1:-v2.34.1}"
PACKAGE_URL="https://github.com/imageio/imageio"
BUILD_DEPS="ffmpeg:n7.0"

SETUPTOOLS_VERSION=">=70"

RH_DEP_PKGS="freetype-devel gcc gcc-c++ gcc-gfortran git libjpeg-devel libtiff-devel libwebp-devel make pkg-config python3-devel wget zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install additional test dependencies
# =============================================================================
pre_test() {
    log_info "Installing additional test dependencies (fsspec, setuptools)..."
    python -m pip install "setuptools>=70" fsspec
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest ignoring test files that require
#           unavailable optional deps or have known failures on this platform
# Ignored:
#   test_freeimage.py                       — requires network access and the
#                                             requests package
#   test_dicom.py                           — OverflowError: Python integer out
#                                             of bounds for uint16 on ppc64le
#   test_core.py                            — known platform failures:
#                                             test_findlib2, test_util_image
#   test_format.py                          — KeyError: 'imageio.plugins.ffmpeg'
# =============================================================================
custom_test_command() {
    log_info "Running imageio tests (ignoring tests requiring unavailable deps)..."
    cd tests
    python -m pytest \
        --ignore=test_pillow.py \
        --ignore=test_pillow_legacy.py \
        --ignore=test_freeimage.py \
        --ignore=test_dicom.py \
        --ignore=test_core.py \
        --ignore=test_format.py
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
