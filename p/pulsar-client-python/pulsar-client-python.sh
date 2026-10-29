#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pulsar-client-python
# Version       : v3.5.0
# Source repo   : https://github.com/apache/pulsar-client-python
# Tested on     : UBI 9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - This package requires building external C++ dependencies:
#     * protobuf v3.20.2 (built from source)
#     * pulsar-client-cpp (built with vcpkg)
#     * pybind11 (built from source)
#   - Uses cmake-based build, not PEP 517 (python -m build)
#   - Container environment provides: rust, node/npm, gcc/g++, cmake
#   - Tests are skipped as the package requires a running Pulsar server
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pulsar-client-python"
PACKAGE_VERSION="${1:-v3.5.0}"
PACKAGE_URL="https://github.com/apache/pulsar-client-python"

# =============================================================================
# Artifact dependencies
# =============================================================================
BUILD_DEPS="protobuf"

# =============================================================================
# REQUIRED: Dependencies
# System packages for building C++ extensions and dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make cmake ninja-build python3-devel python3-pip openssl-devel bzip2-devel libffi-devel zlib-devel autoconf automake libtool cargo llvm llvm-devel clang-tools-extra"
DEB_DEP_PKGS="git gcc g++ make cmake ninja-build python3-dev python3-pip python3-venv libssl-dev libbz2-dev libffi-dev zlib1g-dev autoconf automake libtool cargo llvm llvm-dev clang-tools"
SLES_DEP_PKGS="git gcc gcc-c++ make cmake ninja-build python3-devel python3-pip libopenssl-devel libbz2-devel libffi-devel zlib-devel autoconf automake libtool cargo llvm llvm-devel"

# Skip tests - requires a running Pulsar broker
SKIP_TESTS="true"

# =============================================================================
# CALLBACK: pre_clone
# Set environment variables needed for vcpkg on ppc64le
# =============================================================================
pre_clone() {
    export VCPKG_FORCE_SYSTEM_BINARIES=1
    export CURRENT_DIR="${PWD}"
}

# =============================================================================
# CALLBACK: post_clone
# Build external dependencies: pulsar-client-cpp, pybind11
# Note: protobuf is provided by artifact (BUILD_DEPS)
# =============================================================================
post_clone() {
    log_info "Building external C++ dependencies..."

    # Save current directory (inside cloned repo)
    local REPO_DIR="${PWD}"

    # Verify protobuf artifact is available
    if [[ -z "${PROTOBUF_PREFIX:-}" ]]; then
        log_error "protobuf artifact not found - build p/protobuf/protobuf.sh first"
        return 1
    fi
    log_info "Using protobuf artifact at ${PROTOBUF_PREFIX}"

    # -------------------------------------------------------------------------
    # Build pulsar-client-cpp
    # -------------------------------------------------------------------------
    log_info "Building pulsar-client-cpp..."

    if [[ ! -d "pulsar-client-cpp" ]]; then
        git clone https://github.com/apache/pulsar-client-cpp.git
    fi
    cd pulsar-client-cpp
    git submodule update --init --recursive

    # Build vcpkg for dependency management
    cd vcpkg
    export VCPKG_FORCE_SYSTEM_BINARIES=1
    ./bootstrap-vcpkg.sh
    cd ..

    log_info "Configuring pulsar-client-cpp build..."
    cmake -B build -DINTEGRATE_VCPKG=ON \
        -DCMAKE_PREFIX_PATH="${PROTOBUF_PREFIX}"

    log_info "Building pulsar-client-cpp..."
    cmake --build build -j8

    log_info "Installing pulsar-client-cpp to /tmp/pulsar..."
    cmake -B build -DINTEGRATE_VCPKG=ON -DCMAKE_INSTALL_PREFIX=/tmp/pulsar
    cmake --build build -j8 --target install

    # -------------------------------------------------------------------------
    # Build pybind11
    # -------------------------------------------------------------------------
    log_info "Building pybind11..."
    cd "${REPO_DIR}"

    if [[ ! -d "pybind11" ]]; then
        git clone https://github.com/pybind/pybind11.git
    fi
    cd pybind11
    mkdir -p build && cd build
    cmake ..
    make
    make install

    # Return to the repo directory
    cd "${REPO_DIR}"

    # -------------------------------------------------------------------------
    # Patch CMakeLists.txt: C++11 -> C++17
    # pulsar-client-cpp headers require C++17 (uses std::optional)
    # -------------------------------------------------------------------------
    log_info "Patching CMakeLists.txt for C++17 compatibility..."
    sed -i '/^[[:space:]]*SET(CMAKE_CXX_STANDARD[[:space:]]\+11)[[:space:]]*$/c\
SET(CMAKE_CXX_STANDARD 17)\
SET(CMAKE_CXX_STANDARD_REQUIRED ON)\
SET(CMAKE_CXX_EXTENSIONS OFF)' CMakeLists.txt
}

# =============================================================================
# CALLBACK: custom_install
# Use cmake-based build instead of python -m build
# =============================================================================
custom_install() {
    log_info "Building pulsar-client-python with cmake..."

    local REPO_DIR="${PWD}"
    local CPP_BUILD="${REPO_DIR}/pulsar-client-cpp/build"
    local CPP_INCLUDE="${REPO_DIR}/pulsar-client-cpp/include"

    # Create and activate build venv
    ${PYTHON_VERSION} -m venv .venv-build
    source .venv-build/bin/activate

    pip install --upgrade pip setuptools wheel pyyaml

    # Configure cmake with paths to pulsar-client-cpp
    log_info "Configuring cmake build..."
    cmake -B build \
        -DPULSAR_LIBRARY="${CPP_BUILD}/lib/libpulsar.so" \
        -DPULSAR_INCLUDE="${CPP_INCLUDE}" \
        -DPYBIND11_INCLUDE_DIR="/usr/local/include/pybind11"

    log_info "Building Python extension..."
    cmake --build build -j$(nproc)

    log_info "Installing Python extension..."
    if ! cmake --install build; then
        log_error "cmake install failed"
        deactivate
        return 1
    fi

    # Set library path for runtime
    export LD_LIBRARY_PATH="${CPP_BUILD}/lib:${LD_LIBRARY_PATH}"

    deactivate
    return 0
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
