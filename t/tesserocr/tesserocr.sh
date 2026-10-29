#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tesserocr
# Version       : v2.9.1
# Source repo   : https://github.com/sirfz/tesserocr
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tesserocr"
PACKAGE_VERSION="${1:-v2.9.1}"
PACKAGE_URL="https://github.com/sirfz/tesserocr"

# Tesseract and Leptonica are not available as -devel packages in EPEL 9 ppc64le.
# They are built from source by their own scripts (l/leptonica, t/tesseract) and
# consumed here as artifacts. The python template auto-sources each BUILD_DEPS
# env.sh, which exports LD_LIBRARY_PATH, LIBRARY_PATH, CPATH and PKG_CONFIG_PATH.
BUILD_DEPS="${BUILD_DEPS:-leptonica:1.85.0 tesseract:5.5.1}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="freetype-devel git libjpeg-turbo-devel libpng-devel libtiff-devel python3-devel zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — fetch only the traineddata files the tests use
# (a full tessdata clone is ~129 language files and exhausts disk space in CI)
# =============================================================================
post_clone() {
    log_info "Downloading eng and osd traineddata for TESSDATA_PREFIX"
    mkdir -p tessdata
    for lang in eng osd; do
        if [ ! -f "tessdata/${lang}.traineddata" ]; then
            curl -fL -o "tessdata/${lang}.traineddata" \
                "https://github.com/tesseract-ocr/tessdata/raw/main/${lang}.traineddata"
        fi
    done
    export TESSDATA_PREFIX="$(pwd)/tessdata"
    log_info "TESSDATA_PREFIX=${TESSDATA_PREFIX}"
}

# =============================================================================
# CALLBACK: pre_build — install build dependencies then arm CPPFLAGS/LDFLAGS
# Order matters:
#   1. Install cysignals first (meson probe fails if -ltesseract is in LDFLAGS)
#   2. Install Pillow before setting LDFLAGS (Pillow's C build must not see -ltesseract)
#   3. Set CPPFLAGS/LDFLAGS last so only tesserocr's own build picks them up
# =============================================================================
pre_build() {
    # Fail fast (without exit/return) if the artifacts were not sourced from BUILD_DEPS
    : "${TESSERACT_PREFIX:?tesseract artifact not found - build t/tesseract first}"
    : "${LEPTONICA_PREFIX:?leptonica artifact not found - build l/leptonica first}"

    log_info "Installing Cython (pinned <3.2.0 per setup_requires)"
    python -m pip install "cython>=3.0.0,<3.2.0"
    log_info "Installing cysignals (meson-based; must build before LDFLAGS are set)"
    python -m pip install cysignals
    log_info "Installing Pillow (must build before LDFLAGS are set to avoid -ltesseract contamination)"
    python -m pip install Pillow
    log_info "Setting CPPFLAGS/LDFLAGS for tesserocr build"
    # TESSERACT_PREFIX / LEPTONICA_PREFIX are exported by the artifacts' env.sh
    export CPPFLAGS="-I${TESSERACT_PREFIX}/include -I${LEPTONICA_PREFIX}/include ${CPPFLAGS:-}"
    # leptonica installs as libleptonica.so (not liblept.so) — use -lleptonica
    # --no-as-needed keeps the libs linked even though LDFLAGS places them before the objects
    export LDFLAGS="-L${TESSERACT_PREFIX}/lib -L${LEPTONICA_PREFIX}/lib -Wl,--no-as-needed -ltesseract -lleptonica -Wl,-rpath,${TESSERACT_PREFIX}/lib -Wl,-rpath,${LEPTONICA_PREFIX}/lib ${LDFLAGS:-}"
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps from .venv-build into the fresh .venv-test
# =============================================================================
pre_test() {
    log_info "Installing mirrored build deps for test environment"
    python -m pip install "cython>=3.0.0,<3.2.0" cysignals
    log_info "Installing test dependencies"
    python -m pip install Pillow
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest directly to avoid tox re-building
# from sdist in an isolated env where PKG_CONFIG_PATH/CPATH are not inherited
# =============================================================================
custom_test_command() {
    local tessdata_path
    tessdata_path="$(pwd)/tessdata"
    log_info "Running tesserocr tests with TESSDATA_PREFIX=${tessdata_path}"
    # Pass TESSDATA_PREFIX as an explicit env prefix on the command line so
    # tesseract's C-level getenv() sees it at module import time regardless of
    # any shell export timing. Also deselect test_LSTM_choices: LSTM confidence
    # scores differ on ppc64le due to IEEE 754 floating-point differences.
    TESSDATA_PREFIX="${tessdata_path}" \
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --deselect tests/test_api.py::TestTessBaseApi::test_LSTM_choices \
        tests/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

