#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : boost
# Version       : boost-1.86.0
# Source repo   : https://github.com/boostorg/boost
# Tested on     : UBI:9.6
# Language      : C++
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="boost"
PACKAGE_VERSION="${1:-boost-1.86.0}"
PACKAGE_URL="https://github.com/boostorg/boost"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="boost"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel zlib-devel bzip2-devel xz-devel"
DEB_DEP_PKGS="git python3 python3-dev zlib1g-dev libbz2-dev liblzma-dev"
SLES_DEP_PKGS="git python3 python3-devel zlib-devel libbz2-devel xz-devel"

# =============================================================================
# CALLBACK: custom_install — build and install boost with b2 (--layout=system)
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir boost "${PACKAGE_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        if [[ -r "${ARTIFACT_DIR}/include/boost/version.hpp" ]]; then
            log_info "boost artifact already exists at ${ARTIFACT_DIR}"
        else
            # Headers exist but aren't readable — old b2 default layout left
            # directory symlinks that are now dangling. Fall through to rebuild:
            # b2 with --layout=system will overwrite them with real files.
            log_warn "Cached boost headers unreadable (dangling symlinks). Re-running b2 install with --layout=system..."
        fi
    fi

    log_info "Building boost ${PACKAGE_VERSION} to ${ARTIFACT_DIR}"
    mkdir -p "${ARTIFACT_DIR}"

    export CC=$(which gcc)
    export CXX=$(which g++)

    local TOOLSET="gcc"
    local target_platform
    target_platform="$(uname)-$(uname -m)"

    # Write site-config.jam to pin the compiler for b2
    cat > tools/build/example/site-config.jam << EOF
using ${TOOLSET} : : ${CXX} ;
EOF

    # Architecture-specific b2 flags
    local ARCH_FLAGS=""
    if [[ "${target_platform}" == "Linux-ppc64le" ]]; then
        ARCH_FLAGS="address-model=64 architecture=power binary-format=elf abi=sysv"
    elif [[ "${target_platform}" == "Linux-x86_64" ]]; then
        ARCH_FLAGS="address-model=64 architecture=x86"
    fi

    # --without-charconv: the charconv library was introduced in boost 1.85.0;
    # passing the flag on older versions causes b2 to abort with "wrong library name".
    local WITHOUT_CHARCONV=""
    local _ver="${PACKAGE_VERSION#boost-}"
    local _parts=(${_ver//./ })
    if [[ ${_parts[0]} -gt 1 ]] || [[ ${_parts[0]} -eq 1 && ${_parts[1]} -ge 85 ]]; then
        WITHOUT_CHARCONV="--without-charconv"
    fi

    # Bootstrap the build system
    log_info "Bootstrapping b2..."
    ./bootstrap.sh \
        --prefix="${ARTIFACT_DIR}" \
        --without-libraries=python \
        --with-toolset="${TOOLSET}"

    # Build and install
    # --layout=system: installs headers directly into include/boost/ as real
    # files (no directory symlinks), making the artifact fully self-contained.
    log_info "Building boost libraries..."
    # shellcheck disable=SC2086
    ./b2 -q \
        variant=release \
        ${ARCH_FLAGS} \
        debug-symbols=off \
        threading=multi \
        runtime-link=shared \
        link=shared \
        toolset="${TOOLSET}" \
        --layout=system \
        ${WITHOUT_CHARCONV} \
        --without-python \
        --prefix="${ARTIFACT_DIR}" \
        -j"$(nproc)" \
        install

    # Remove unnecessary files (man pages, docs)
    cleanup_artifact_dir "${ARTIFACT_DIR}" share

    # Copy license
    cp LICENSE_1_0.txt "${ARTIFACT_DIR}/LICENSE"

    # Generate env.sh
    # Export both BOOST_ROOT (legacy) and Boost_ROOT (cmake CMP0144)
    cat > "${ARTIFACT_DIR}/env.sh" << EOF
# boost ${PACKAGE_VERSION} environment
export BOOST_PREFIX="${ARTIFACT_DIR}"
export BOOST_ROOT="${ARTIFACT_DIR}"
export Boost_ROOT="${ARTIFACT_DIR}"
export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${ARTIFACT_DIR}/lib:\${LIBRARY_PATH:-}"
export CPATH="${ARTIFACT_DIR}/include:\${CPATH:-}"
export CMAKE_PREFIX_PATH="${ARTIFACT_DIR}:\${CMAKE_PREFIX_PATH:-}"
EOF

    # Generate manifest
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "boost" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "BSL-1.0"

    log_info "boost installed to ${ARTIFACT_DIR}"
}

# =============================================================================
# Skip tests for native library build
# =============================================================================
SKIP_TESTS=true
LICENSE_SPDX="BSL-1.0"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../templates/base.sh"

