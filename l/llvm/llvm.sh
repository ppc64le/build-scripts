#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : llvm
# Version       : llvmorg-18.1.8
# Source repo   : https://github.com/llvm/llvm-project
# Tested on     : UBI:9.6
# Language      : C++
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="llvm"
PACKAGE_VERSION="${1:-llvmorg-18.1.8}"
PACKAGE_URL="https://github.com/llvm/llvm-project"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="llvm"
ARTIFACT_VERSION="${PACKAGE_VERSION}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git cmake make ninja-build python3 zlib-devel libffi-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_install — build LLVM from llvm/ subdirectory of monorepo
#   The llvm-project top-level CMakeLists.txt is the monorepo root and cannot
#   be used as the cmake source directly for a standalone LLVM build.
#   We must point cmake at llvm/ explicitly. This also avoids the template
#   injecting conflicting -DBUILD_SHARED_LIBS and -DCMAKE_BUILD_TYPE flags.
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}, skipping build"
        return 0
    fi

    log_info "Building LLVM ${PACKAGE_VERSION} from llvm/ subdirectory"
    mkdir -p "${ARTIFACT_DIR}"
    mkdir -p build
    cd build

    cmake ../llvm \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DLLVM_ENABLE_PROJECTS="" \
        -DLLVM_TARGETS_TO_BUILD="PowerPC;X86;AArch64" \
        -DLLVM_ENABLE_RTTI=ON \
        -DLLVM_ENABLE_FFI=ON \
        -DLLVM_ENABLE_ZLIB=ON \
        -DLLVM_BUILD_LLVM_DYLIB=ON \
        -DLLVM_LINK_LLVM_DYLIB=ON \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_INCLUDE_DOCS=OFF \
        -DLLVM_PARALLEL_LINK_JOBS=1 \
        -DLLVM_USE_SPLIT_DWARF=ON

    cmake --build . --parallel "$(nproc)"
    cmake --install .
    cd ..

    _cleanup_artifact "${ARTIFACT_DIR}"
    _copy_license "${ARTIFACT_DIR}"
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}"

    # Export LLVM_CONFIG and CMAKE_PREFIX_PATH helpers for downstream consumers
    echo 'export LLVM_CONFIG="${LLVM_PREFIX}/bin/llvm-config"' >> "${ARTIFACT_DIR}/env.sh"
    echo 'export CMAKE_PREFIX_PATH="${LLVM_PREFIX}:${LLVM_PREFIX}/lib/cmake/llvm:${CMAKE_PREFIX_PATH:-}"' >> "${ARTIFACT_DIR}/env.sh"

    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}"

    log_info "LLVM build complete: ${ARTIFACT_DIR}"
}

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="Apache-2.0"
SKIP_TESTS="true"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
