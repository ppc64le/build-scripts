#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : c-ares
# Version       : v1.34.4
# Source repo   : https://github.com/c-ares/c-ares
# Tested on     : UBI:9.6
# Language      : C / Python Wheel
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - Async DNS resolver library
#   - Required by grpc and other networking packages
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="c-ares"
PACKAGE_VERSION="${1:-v1.34.4}"
PACKAGE_URL="https://github.com/c-ares/c-ares"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="c-ares"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make python3 python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ cmake make python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make python3 python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_build
# Compiles the C library and prepares the python package layout
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}. Skipping entire build."
        return 0
    fi

    log_info "Compiling native c-ares library..."
    mkdir -p "${ARTIFACT_DIR}" build
    cd build

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCARES_SHARED=ON \
        -DCARES_STATIC=OFF \
        -DCARES_INSTALL=ON \
        -DCMAKE_INSTALL_LIBDIR=lib \
        ..
    make -j"$(nproc)"
    make install
    cd ..

    # Export LD_LIBRARY_PATH so auditwheel can find the compiled shared libraries to repair the wheel
    export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${LD_LIBRARY_PATH:-}"

    # Prepare the python packaging layout
    mkdir -p local/cares
    touch local/cares/__init__.py
    cp -r "${ARTIFACT_DIR}/lib" local/cares/
    cp -r "${ARTIFACT_DIR}/include" local/cares/

    # Sanitized PEP 440 version for the python wheel configuration
    local artifact_version="${PACKAGE_VERSION#v}"
    artifact_version="${artifact_version#cares-}"
    artifact_version="${artifact_version//_/.}"

    # Copy pyproject.toml from the script directory and replace the version placeholder
    log_info "Preparing pyproject.toml..."
    if [[ -f "${SCRIPT_DIR}/pyproject.toml" ]]; then
        sed "s/{PACKAGE_VERSION}/${artifact_version}/g" "${SCRIPT_DIR}/pyproject.toml" > pyproject.toml
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
LICENSE_SPDX="MIT"

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
