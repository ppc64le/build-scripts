#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : re2
# Version       : 2024-07-02
# Source repo   : https://github.com/google/re2
# Tested on     : UBI:9.6
# Language      : C++ / Python Wheel
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 1 artifact provider (depends on abseil-cpp)
#   - Fast, safe regex library by Google
#   - Required by grpc and other packages
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="re2"
PACKAGE_VERSION="${1:-2024-07-02}"
PACKAGE_URL="https://github.com/google/re2"

# =============================================================================
# Artifact Declaration (Tier 1 - depends on abseil-cpp)
# =============================================================================
PROVIDES_ARTIFACT="re2"
BUILD_DEPS="${BUILD_DEPS:-abseil-cpp}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make python3 python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ cmake make python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make python3 python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_build
# Compiles re2 C++ library and prepares python package directory structure
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}. Skipping entire build."
        return 0
    fi

    log_info "Compiling native re2 C++ library..."
    mkdir -p "${ARTIFACT_DIR}" build
    cd build

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_PREFIX_PATH="${ABSEIL_CPP_PREFIX}" \
        -DRE2_BUILD_TESTING=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        ..
    make -j"$(nproc)"
    make install
    cd ..

    # Export LD_LIBRARY_PATH (including abseil-cpp prefix) so auditwheel can find all dependencies during repair
    export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${ABSEIL_CPP_PREFIX}/lib:${LD_LIBRARY_PATH:-}"

    # Prepare the python packaging layout
    mkdir -p local/re2
    touch local/re2/__init__.py
    cp -r "${ARTIFACT_DIR}/lib" local/re2/
    cp -r "${ARTIFACT_DIR}/include" local/re2/

    # Clean version string to make it PEP-440 compliant
    # Replace hyphens with dots (e.g. 2024-07-02 -> 2024.07.02)
    local CLEAN_VERSION
    CLEAN_VERSION="${PACKAGE_VERSION//-/.}"

    # Copy pyproject.toml from the script directory and replace the version placeholder
    log_info "Preparing pyproject.toml..."
    if [[ -f "${SCRIPT_DIR}/pyproject.toml" ]]; then
        sed "s/{PACKAGE_VERSION}/${CLEAN_VERSION}/g" "${SCRIPT_DIR}/pyproject.toml" > pyproject.toml
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
        "${PACKAGE_URL}" "${LICENSE_SPDX}" \
        "abseil-cpp"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_WHEEL="true"
SKIP_TESTS=true
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

