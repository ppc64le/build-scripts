#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : scikit-image
# Version       : v0.26.0
# Source repo   : https://github.com/scikit-image/scikit-image
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="scikit-image"
PACKAGE_VERSION="${1:-v0.26.0}"
PACKAGE_URL="https://github.com/scikit-image/scikit-image"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel cmake git libevent-devel libffi-devel libgomp libjpeg-turbo-devel libtool make ninja-build openblas openblas-devel openssl-devel python3-devel sqlite-devel wget xz zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_clone — rewrite git:// submodule URLs to https:// to avoid timeouts
# =============================================================================
pre_clone() {
    log_info "Configuring git to rewrite git:// to https://"
    git config --global url."https://github.com/".insteadOf git://github.com/
}

# =============================================================================
# CALLBACK: post_clone — apply meson build patches and sanitize requirements
# =============================================================================
post_clone() {
    if [[ -f "requirements/default.txt" ]]; then
        log_info "Replacing requirements.txt with requirements/default.txt to avoid pulling heavy test dependencies"
        cp requirements/default.txt requirements.txt
    fi

    local version_num="${PACKAGE_VERSION#v}"
    if [[ "${version_num}" == "0.25."* ]]; then
        log_info "Applying meson patches for ${PACKAGE_VERSION} (v0.25)..."
        git apply "${SCRIPT_DIR}/patches/skimage-meson-v0.25.patch"
    elif [[ "$(printf '%s\n' "0.26.0" "${version_num}" | sort -V | head -n1)" == "${version_num}" ]] && \
         [[ "${version_num}" != "0.26.0" ]]; then
        log_info "Applying meson patches for ${PACKAGE_VERSION} (v0.22–v0.24)..."
        git apply "${SCRIPT_DIR}/patches/skimage-meson-v0.22-v0.24.patch"
    else
        log_info "Applying meson patches for ${PACKAGE_VERSION} (v0.26+)..."
        git apply "${SCRIPT_DIR}/patches/skimage-meson-v0.26.patch"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install build backend dependencies and requirements
# =============================================================================
pre_build() {
    if [[ -f "requirements/build.txt" ]]; then
        log_info "Installing build requirements from requirements/build.txt"
        python -m pip install -r requirements/build.txt
    fi
    if [[ -f "requirements/default.txt" ]]; then
        log_info "Installing runtime requirements from requirements/default.txt"
        python -m pip install -r requirements/default.txt
    elif [[ -f "requirements.txt" ]]; then
        log_info "Installing runtime requirements from requirements.txt"
        python -m pip install -r requirements.txt
    fi

    log_info "Ensuring core build backend tools are installed"
    python -m pip install cython meson-python meson ninja "pythran>=0.16" "wheel<0.48.0" tomli build

    ln -sfn "${PWD}/.venv-build" /tmp/ext_venv
}

# =============================================================================
# CALLBACK: custom_install — build wheel directly with parallel compilation
# =============================================================================
custom_install() {
    local _nproc; _nproc=$(nproc 2>/dev/null || echo 4)
    local jobs=$(( _nproc > 4 ? 4 : _nproc ))
    log_info "Building scikit-image wheel (parallel jobs: ${jobs})"
    export NPY_NUM_BUILD_JOBS="${jobs}"
    export CMAKE_BUILD_PARALLEL_LEVEL="${jobs}"
    export MAKEFLAGS="-j${jobs}"

    export CXXFLAGS="${CXXFLAGS:-} -ftemplate-depth=5000 -std=c++17"
    log_info "CXXFLAGS=${CXXFLAGS}"

    rm -rf build build_dir dist
    mkdir -p dist
    python -m build --no-isolation --wheel --skip-dependency-check --outdir dist/

    local wheel; wheel=$(ls dist/*.whl 2>/dev/null | head -n1)
    if [[ -z "${wheel}" ]]; then
        log_error "Wheel build failed: no wheel found in dist/"
        false
    fi
    python -m pip install "${wheel}"
}

# =============================================================================
# CALLBACK: custom_test_command — import smoke-test (full tests require display/GUI environment)
# =============================================================================
custom_test_command() {
    log_info "Verifying package import outside source directory to avoid shadowing"
    (cd "$HOME" && python -c "import skimage; print('scikit-image version:', skimage.__version__)")
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
