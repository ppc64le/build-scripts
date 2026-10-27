#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : fastavro
# Version       : 1.12.1
# Source repo   : https://github.com/fastavro/fastavro
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="fastavro"
PACKAGE_VERSION="${1:-1.12.1}"
PACKAGE_URL="https://github.com/fastavro/fastavro"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building fastavro
# Note: gcc/g++, cmake are provided by the container
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
export FASTAVRO_USE_CYTHON=1

# =============================================================================
# CALLBACK: post_clone — read setuptools requirement from pyproject.toml
# =============================================================================
post_clone() {
    log_info "Reading setuptools version requirement from pyproject.toml"
    if [[ -f "pyproject.toml" ]]; then
        setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
        if [[ -n "$setuptools_req" ]]; then
            SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
            SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
            log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
        else
            log_info "No setuptools pin found in pyproject.toml — using template default"
        fi
    else
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install Cython build dependency
# fastavro 1.9.7 uses cpython/int.pxd (PyInt_AS_LONG) which was removed in
# Cython 3.3.0. Pin to 3.0.12 which retains the PyInt_AS_LONG->PyLong_AS_LONG
# shim and supports Python 3.13/3.14. fastavro 1.12.1 is unaffected by this pin.
# =============================================================================
pre_build() {
    log_info "Installing Cython build dependency..."
    python -m pip install "cython==3.0.12" wheel
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into test venv and install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing build backend and test dependencies..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "cython==3.0.12" \
        "numpy<2.0; python_version < '3.13'" \
        "numpy; python_version >= '3.13'" \
        pandas zlib-ng \
        "backports.zstd; python_version < '3.14'" \
        "zstandard; python_version < '3.14'" \
        "zstandard; python_version >= '3.14'" \
        lz4 cramjam
    export PIP_NO_BUILD_ISOLATION=1
}

# =============================================================================
# CALLBACK: custom_test_command — build Cython extensions in-place then run pytest
# =============================================================================
custom_test_command() {
    log_info "Building Cython extensions in-place..."
    python setup.py build_ext --inplace
    log_info "Running pytest..."
    # Skip test_pandas_datetime because building pandas from source on ppc64le generates
    # faulty C extensions under Python >= 3.14, leading to segmentation faults.
    # Note: Using the IBM prebuilt pandas wheel from the developerfirst URL (https://wheels.developerfirst.ibm.com/ppc64le/linux/) works.
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        -k "not test_pandas_datetime"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
