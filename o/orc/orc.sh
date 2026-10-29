#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : orc
# Version       : v2.0.3
# Source repo   : https://github.com/apache/orc
# Tested on     : UBI:9.6
# Language      : C++
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="orc"
PACKAGE_VERSION="${1:-v2.0.3}"
PACKAGE_URL="https://github.com/apache/orc"

# =============================================================================
# Artifact Declaration (Tier 1 - no external native dependencies)
# =============================================================================
PROVIDES_ARTIFACT="orc"
ARTIFACT_VERSION="${PACKAGE_VERSION#v}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git cmake make openssl-devel zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="Apache-2.0"

# =============================================================================
# CALLBACK: custom_install — build Apache ORC via cmake and install to artifact directory
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}, skipping build"
    else
        log_info "Building Apache ORC ${PACKAGE_VERSION} → ${ARTIFACT_DIR} ..."
        mkdir -p "${ARTIFACT_DIR}" build
        cd build

        # No *_HOME flags: ORC vendors protobuf 3.5.1/snappy/zstd as static libs.
        # Passing external protobuf v4/v5 (abseil-linked) causes ABI mismatch.
        # -DBUILD_TOOLS=OFF: tool binaries unnecessary for the artifact.
        # -DINSTALL_VENDORED_LIBS=OFF: consumers link liborc.so only.
        # -Wno-error=unused-parameter: ppc64le SIMD stubs in CpuInfoUtil.cc.
        cmake \
            -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_FLAGS="-Wno-error=unused-parameter" \
            -DBUILD_JAVA=OFF \
            -DBUILD_TOOLS=OFF \
            -DBUILD_CPP_TESTS=OFF \
            -DBUILD_LIBHDFSPP=OFF \
            -DINSTALL_VENDORED_LIBS=OFF \
            ..

        make -j"$(nproc)"
        make install
        cd ..
    fi
}

# =============================================================================
# CALLBACK: post_build — package artifact environment, license, and manifest
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    _cleanup_artifact "${ARTIFACT_DIR}"
    _copy_license "${ARTIFACT_DIR}"
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}"
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}"
}

# =============================================================================
# CALLBACK: custom_test_command — verify the library links correctly
# =============================================================================
custom_test_command() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    log_info "Running link test against liborc..."
    local test_file="/tmp/orc_test.cpp"
    cat > "${test_file}" << 'EOF'
#include <orc/OrcFile.hh>
#include <iostream>
int main() {
    std::cout << "orc link test passed" << std::endl;
    return 0;
}
EOF
    g++ -o /tmp/orc_test "${test_file}" \
        -I"${ARTIFACT_DIR}/include" \
        -L"${ARTIFACT_DIR}/lib" \
        -lorc -pthread -std=c++17
    LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${LD_LIBRARY_PATH:-}" /tmp/orc_test
    rm -f /tmp/orc_test /tmp/orc_test.cpp
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

