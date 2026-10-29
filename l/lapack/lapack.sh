#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : lapack
# Version       : v3.12.1
# Source repo   : https://github.com/Reference-LAPACK/lapack
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="lapack"
PACKAGE_VERSION="${1:-v3.12.1}"
PACKAGE_URL="https://github.com/Reference-LAPACK/lapack"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ gcc-gfortran make cmake wget"
DEB_DEP_PKGS="git gcc g++ gfortran make cmake wget"
SLES_DEP_PKGS="git gcc gcc-c++ gcc-fortran make cmake wget"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="lapack"

# =============================================================================
# CALLBACK: custom_install — Build LAPACK with CMake and prepare Python wheel layout
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION#v}")"

    log_info "Building LAPACK with CMake"
    mkdir -p "${ARTIFACT_DIR}" cmake_build
    cd cmake_build

    if ! cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DLAPACKE=ON \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_INSTALL_LIBDIR=lib; then
        log_error "CMake configuration failed"
        return 1
    fi

    if ! make -j"$(nproc)"; then
        log_error "Build failed"
        return 1
    fi

    if ! cmake --install .; then
        log_error "Installation failed"
        return 1
    fi

    cd ..

    # Export LD_LIBRARY_PATH so auditwheel can find the compiled shared libraries
    export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${LD_LIBRARY_PATH:-}"

    # Prepare the python packaging layout
    mkdir -p local/lapack
    touch local/lapack/__init__.py
    cp -r "${ARTIFACT_DIR}/lib" local/lapack/
    cp -r "${ARTIFACT_DIR}/include" local/lapack/

    # Set RPATH on the wheel libs to $ORIGIN so that when auditwheel scans them,
    # libblas and liblapack resolve to the copies already inside the wheel
    # (lapack/lib/) instead of being grafted a second time into lapack.libs/.
    find local/lapack/lib -maxdepth 1 -type f -name '*.so*' \
        -exec patchelf --force-rpath --set-rpath '$ORIGIN' {} \;

    # Copy pyproject.toml from the script directory and replace the version placeholder
    log_info "Preparing pyproject.toml..."
    if [[ -f "${SCRIPT_DIR}/pyproject.toml" ]]; then
        sed "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#v}/g" "${SCRIPT_DIR}/pyproject.toml" > pyproject.toml
    else
        log_error "Static pyproject.toml template not found in ${SCRIPT_DIR}"
        return 1
    fi

    log_info "LAPACK build and installation complete"
}

# =============================================================================
# CALLBACK: post_build — Package the artifact environment and generate the manifest
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION#v}")"

    _cleanup_artifact "${ARTIFACT_DIR}"
    _copy_license "${ARTIFACT_DIR}"
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION#v}"
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION#v}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}"
}

# =============================================================================
# CALLBACK: custom_test_command — run ctest
# =============================================================================
custom_test_command() {
    log_info "Running LAPACK tests with ctest"

    if ! (cd cmake_build && ctest --output-on-failure); then
        log_error "LAPACK tests failed"
        return 1
    fi

    log_info "LAPACK tests passed successfully"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_WHEEL="true"
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
