#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : chroma-hnswlib
# Version       : 0.8.0
# Source repo   : https://github.com/chroma-core/hnswlib
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="chroma-hnswlib"
PACKAGE_VERSION="${1:-0.8.0}"
PACKAGE_URL="https://github.com/chroma-core/hnswlib"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel gcc gcc-c++ cmake"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — patch -march=native to -mcpu=native for ppc64le
# =============================================================================
post_clone() {
    log_info "Patching -march=native to -mcpu=native for ppc64le compatibility"
    # -march=native is x86-specific; ppc64le uses -mcpu=native
    sed -i 's/-march=native/-mcpu=native/g' setup.py || true
    sed -i 's/-march=native/-mcpu=native/g' CMakeLists.txt || true
}

# =============================================================================
# CALLBACK: pre_build — install C-extension build dependencies
# =============================================================================
pre_build() {
    log_info "Installing build dependencies: pip, setuptools, wheel, numpy, pybind11"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install numpy pybind11
}

# =============================================================================
# CALLBACK: pre_test — mirror build dependencies into the test venv
# =============================================================================
pre_test() {
    log_info "Installing build dependencies into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install numpy pybind11
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"