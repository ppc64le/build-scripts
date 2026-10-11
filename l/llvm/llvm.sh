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
# CALLBACK: post_clone - Forward top-level CMakeLists.txt to llvm subdirectory
# =============================================================================
post_clone() {
    log_info "Creating top-level CMakeLists.txt to forward build to llvm subdirectory"
    cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.20)
project(llvm_top)
add_subdirectory(llvm)
EOF
}

# =============================================================================
# CALLBACK: post_build - Add LLVM_CONFIG and LLVM CMake/bin helpers to env.sh
# =============================================================================
post_build() {
    log_info "Writing LLVM_CONFIG and CMAKE_PREFIX_PATH exports to env.sh"
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    echo 'export LLVM_CONFIG="${LLVM_PREFIX}/bin/llvm-config"' >> "${ARTIFACT_DIR}/env.sh"
    echo 'export CMAKE_PREFIX_PATH="${LLVM_PREFIX}:${LLVM_PREFIX}/lib/cmake/llvm:${CMAKE_PREFIX_PATH:-}"' >> "${ARTIFACT_DIR}/env.sh"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_SYSTEM="cmake"
CMAKE_OPTS="-G Ninja -DBUILD_SHARED_LIBS=OFF -DLLVM_ENABLE_PROJECTS= -DLLVM_TARGETS_TO_BUILD=PowerPC;X86;AArch64 -DLLVM_ENABLE_RTTI=ON -DLLVM_ENABLE_FFI=ON -DLLVM_ENABLE_ZLIB=ON -DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON -DLLVM_ENABLE_ASSERTIONS=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_DOCS=OFF"
LICENSE_SPDX="Apache-2.0"
SKIP_TESTS="true"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../templates/base.sh"
