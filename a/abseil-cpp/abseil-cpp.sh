#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : abseil-cpp
# Version       : 20240116.2
# Source repo   : https://github.com/abseil/abseil-cpp
# Tested on     : UBI:9.6
# Language      : C++ / Python Wheel
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - Required by protobuf, grpc, and other packages
#   - Built with C++17 standard and shared libraries
#   - Uses Ninja generator for faster builds
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="abseil-cpp"
PACKAGE_VERSION="${1:-20240116.2}"
PACKAGE_URL="https://github.com/abseil/abseil-cpp"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="abseil-cpp"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake ninja-build python3 python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ cmake ninja-build python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ cmake ninja python3 python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_build
# Compiles the C++ library and prepares the python package layout
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}. Skipping entire build."
        return 0
    fi

    log_info "Compiling native C++ abseil-cpp library..."
    mkdir -p "${ARTIFACT_DIR}" build
    cd build

    cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON \
        -DABSL_BUILD_TESTING=OFF \
        -DABSL_PROPAGATE_CXX_STD=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        ..
    cmake --build . -j"$(nproc)"
    cmake --install .
    cd ..

    # Export LD_LIBRARY_PATH so auditwheel can find the compiled shared libraries to repair the wheel
    export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${LD_LIBRARY_PATH:-}"

    # Prepare the python packaging layout
    mkdir -p local/abseilcpp
    touch local/abseilcpp/__init__.py
    cp -r "${ARTIFACT_DIR}/lib" local/abseilcpp/
    cp -r "${ARTIFACT_DIR}/include" local/abseilcpp/

    # Copy pyproject.toml from the script directory and replace the version placeholder
    log_info "Preparing pyproject.toml..."
    if [[ -f "${SCRIPT_DIR}/pyproject.toml" ]]; then
        sed "s/{PACKAGE_VERSION}/${PACKAGE_VERSION}/g" "${SCRIPT_DIR}/pyproject.toml" > pyproject.toml
    else
        log_error "Static pyproject.toml template not found in ${SCRIPT_DIR}"
        return 1
    fi
}

# =============================================================================
# CALLBACK: post_build
# Packages the artifact environment and manifest
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    # Use base.sh helpers for standard post-build tasks
    _cleanup_artifact "${ARTIFACT_DIR}"
    _copy_license "${ARTIFACT_DIR}"
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}"
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_WHEEL="true"
SKIP_TESTS=true
LICENSE_SPDX="Apache-2.0"

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
