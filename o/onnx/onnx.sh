#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : onnx
# Version       : v1.17.0
# Source repo   : https://github.com/onnx/onnx
# Tested on     : UBI:9.6
# Language      : Python, C++
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="onnx"
PACKAGE_VERSION="${1:-v1.17.0}"
PACKAGE_URL="https://github.com/onnx/onnx"

BUILD_DEPS="abseil-cpp libprotobuf"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip cmake ninja-build"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

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
        # No pyproject.toml present — fall back to a safe upper bound
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — verify libprotobuf artifact and install build deps
# =============================================================================
pre_build() {
    # Check if libprotobuf environment / protoc binary is available
    if ! command -v protoc &> /dev/null; then
        log_error "protoc not found. libprotobuf artifact was not sourced correctly!"
    fi
    log_info "Using protoc: $(which protoc) ($(protoc --version))"

    # Install Python build dependencies
    log_info "Installing Python build dependencies..."
    python -m pip install numpy pybind11 protobuf cmake pytest-runner

    # Enforce C++17 for compatibility with abseil-cpp and libprotobuf artifacts
    export CXXFLAGS="-std=c++17"
    export CMAKE_ARGS="-DONNX_USE_PROTOBUF_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_STANDARD_REQUIRED=ON -DCMAKE_CXX_EXTENSIONS=OFF -DCMAKE_CXX_FLAGS=-std=c++17 -DPython3_EXECUTABLE=$(which python)"
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies and mirror build backend
# =============================================================================
pre_test() {
    log_info "Installing build backend and mirroring build dependencies in test venv..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install numpy pybind11 protobuf cmake pytest nbval parameterized
    python -m pip install --upgrade "pytest>=7.0"
    python -m pip uninstall -y pytest-cov pytest-xdist 2>/dev/null 
}

# =============================================================================
# CALLBACK: custom_test_command — run ONNX test suite
# =============================================================================
custom_test_command() {
    log_info "Running ONNX basic tests..."
    # CWD is inside the clone root (/workspace/onnx) which contains a source
    # 'onnx/' directory. Even with PYTHONPATH prepended, Python resolves 'onnx'
    # imports through the source tree because pyproject.toml (v1.16.0 sets
    # testpaths/addopts) keeps /workspace/onnx on sys.path via pytest rootdir.
    #
    # python -I (isolated mode) ignores PYTHONPATH, CWD, and user site-packages
    # so only the installed wheel is importable. --pyargs resolves the test
    # module by name through the installed package, never touching the source
    # tree. Pattern follows dm-tree.sh in this repo.
    python -I -m pytest \
        --pyargs onnx.test.basic_test \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        -v
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
