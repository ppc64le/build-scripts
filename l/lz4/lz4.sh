#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : lz4
# Version       : v4.4.5
# Source repo   : https://github.com/python-lz4/python-lz4
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Varsha Kumar <varsha.kumar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="lz4"
PACKAGE_VERSION="${1:-v4.4.5}"
PACKAGE_URL="https://github.com/python-lz4/python-lz4"

BUILD_DEPS="${BUILD_DEPS:-psutil:v7.2.1}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — set version for setuptools_scm
# =============================================================================
post_clone() {
    local semver="${PACKAGE_VERSION#v}"
    export SETUPTOOLS_SCM_PRETEND_VERSION="${semver}"
    log_info "Set SETUPTOOLS_SCM_PRETEND_VERSION=${semver}"
}

# =============================================================================
# CALLBACK: pre_build — install build-time dependencies
# =============================================================================
pre_build() {
    log_info "Installing build-time dependencies"
    python -m pip install "setuptools_scm[toml]>=6.2" pkgconfig
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install pytest pytest-timeout

    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    local psutil_wheel=""
    if [[ -n "${PSUTIL_PREFIX:-}" && -d "${PSUTIL_PREFIX}/wheels" ]]; then
        psutil_wheel=$(find "${PSUTIL_PREFIX}/wheels" -name "psutil-*-${python_abi}-${python_abi}-*.whl" 2>/dev/null | head -1)
        if [[ -z "${psutil_wheel}" ]]; then
            psutil_wheel=$(find "${PSUTIL_PREFIX}/wheels" -name "psutil-*-abi3-*.whl" 2>/dev/null | head -1)
        fi
    fi

    if [[ -n "${psutil_wheel}" ]]; then
        log_info "Installing psutil wheel: ${psutil_wheel}"
        python -m pip install --no-deps --ignore-installed "${psutil_wheel}"
        local psutil_site="${PSUTIL_PREFIX}/lib/python$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")/site-packages"
        while [[ "${PYTHONPATH:-}" == "${psutil_site}" || "${PYTHONPATH:-}" == "${psutil_site}:"* ]]; do
            [[ "${PYTHONPATH}" == "${psutil_site}" ]] && { unset PYTHONPATH; break; }
            export PYTHONPATH="${PYTHONPATH#${psutil_site}:}"
        done
    elif [[ -n "${PSUTIL_PREFIX:-}" && -d "${PSUTIL_PREFIX}" ]]; then
        log_warn "No psutil wheel for ${python_abi} found in artifact — using artifact PYTHONPATH"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — run tests from specific directories
# =============================================================================
custom_test_command() {
    # The template installs the wheel without --force-reinstall, so pip skips it
    # when lz4 metadata is already present from the build venv. Force-install here
    # to ensure the compiled .so extensions land in the test venv site-packages.
    if ls "${OUTPUT_DIR}"/*.whl 1>/dev/null 2>&1; then
        log_info "Force-installing lz4 wheel into test venv"
        python -m pip install --force-reinstall --no-deps "${OUTPUT_DIR}"/*.whl
    fi

    log_info "Running version check"
    python -c "import importlib.metadata; print('lz4 version:', importlib.metadata.version('lz4'))"

    log_info "Running upstream unit tests"
    # Skipping tracemalloc-based memory tests in test_frame_5.py: time out (>60s) on ppc64le.
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        tests/block/ \
        tests/frame/ \
        -v \
        --timeout=60 \
        --deselect=tests/frame/test_frame_5.py::test_frame_decompress_mem_usage \
        --deselect=tests/frame/test_frame_5.py::test_frame_decompress_chunk_mem_usage \
        --deselect=tests/frame/test_frame_5.py::test_frame_open_decompress_mem_usage
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
