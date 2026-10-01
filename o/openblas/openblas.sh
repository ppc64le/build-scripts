#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : OpenBLAS
# Version       : v0.3.29
# Source repo   : https://github.com/OpenMathLib/OpenBLAS
# Tested on     : UBI:9.6
# Language      : C, Fortran / Python Wheel
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier 0 artifact provider (no native dependencies)
#   - Built with POWER9 target for ppc64le optimization
#   - Provides libopenblas.so for numpy, scipy, pytorch, etc.
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="OpenBLAS"
PACKAGE_VERSION="${1:-v0.3.29}"
PACKAGE_URL="https://github.com/OpenMathLib/OpenBLAS"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="openblas"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ gcc-gfortran make python3 python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ gfortran make python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ gcc-fortran make python3 python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_build
# Compiles OpenBLAS and prepares the python packaging folder
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}. Skipping entire build."
        return 0
    fi

    mkdir -p "${ARTIFACT_DIR}"

    # Detect architecture and set appropriate target
    local target="GENERIC"
    case "$(uname -m)" in
        ppc64le) target="POWER9" ;;
        x86_64)  target="HASWELL" ;;
        aarch64) target="ARMV8" ;;
    esac

    # Build options
    local build_opts=(
        "USE_OPENMP=1" "BINARY=64" "DYNAMIC_ARCH=1" "TARGET=${target}"
        "INTERFACE64=0" "NO_LAPACK=0" "USE_THREAD=1" "NUM_THREADS=64" "NO_AFFINITY=1"
    )

    log_info "Building with target=${target}"
    make "${build_opts[@]}" -j"$(nproc)"
    make install PREFIX="${ARTIFACT_DIR}" "${build_opts[@]}"

    # Export LD_LIBRARY_PATH so auditwheel can find the compiled shared libraries to repair the wheel
    export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${LD_LIBRARY_PATH:-}"

    # Prepare the python packaging layout
    mkdir -p local/openblas
    touch local/openblas/__init__.py
    cp -r "${ARTIFACT_DIR}/lib" local/openblas/
    cp -r "${ARTIFACT_DIR}/include" local/openblas/

    # Copy pyproject.toml from the script directory and replace the version placeholder
    log_info "Preparing pyproject.toml..."
    if [[ -f "${SCRIPT_DIR}/pyproject.toml" ]]; then
        sed "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#v}/g" "${SCRIPT_DIR}/pyproject.toml" > pyproject.toml
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
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
