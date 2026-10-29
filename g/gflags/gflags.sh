#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : gflags
# Version       : v2.2.2
# Source repo   : https://github.com/gflags/gflags
# Tested on     : UBI:9.6
# Language      : C++
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="gflags"
PACKAGE_VERSION="${1:-v2.2.2}"
PACKAGE_URL="https://github.com/gflags/gflags"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="gflags"
ARTIFACT_VERSION="${PACKAGE_VERSION#v}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make"
DEB_DEP_PKGS="git gcc g++ cmake make"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make"

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_FILE="COPYING.txt"
LICENSE_SPDX="BSD-3-Clause"
SKIP_TESTS="true"

# =============================================================================
# CALLBACK: custom_install — build and stage gflags artifact
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    # env.sh + libgflags.so is not enough: a cache-restored artifact can hold only
    # some of the files.  gflags installs several libraries (libgflags,
    # libgflags_nothreads) and its cmake target files list all of them, so a
    # missing one makes find_package(gflags) fail in Arrow:
    #   The imported target "gflags_nothreads_shared" references the file
    #   ".../lib/libgflags_nothreads.so.2.2.2" but this file does not exist.
    # Rebuild unless every library referenced by the cmake target files exists.
    local _rebuild=true
    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        local _ref _incomplete=false
        if [[ ! -f "${ARTIFACT_DIR}/lib/libgflags.so" ]] && \
           [[ ! -f "${ARTIFACT_DIR}/lib64/libgflags.so" ]]; then
            _incomplete=true
        fi
        while IFS= read -r _ref; do
            if [[ ! -e "${ARTIFACT_DIR}/${_ref}" ]]; then
                log_warn "gflags artifact at ${ARTIFACT_DIR} is incomplete (${_ref} missing)"
                _incomplete=true
                break
            fi
        done < <(grep -rhoE '\$\{_IMPORT_PREFIX\}/lib(64)?/[^" ;)]+' \
                    "${ARTIFACT_DIR}"/lib/cmake/gflags 2>/dev/null \
                  | sed 's|^\${_IMPORT_PREFIX}/||')
        if [[ "${_incomplete}" == "false" ]]; then
            log_info "gflags artifact already exists at ${ARTIFACT_DIR}"
            _rebuild=false
        else
            log_warn "Rebuilding gflags artifact at ${ARTIFACT_DIR}"
            rm -rf "${ARTIFACT_DIR}"
        fi
    fi

    if [[ "${_rebuild}" == "true" ]]; then
        log_info "Configuring and building gflags ${PACKAGE_VERSION}..."
        mkdir -p "${ARTIFACT_DIR}" build && cd build
        cmake -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
            -DCMAKE_INSTALL_LIBDIR=lib \
            -DBUILD_SHARED_LIBS=ON \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DBUILD_STATIC_LIBS=OFF \
            -DBUILD_TESTING=OFF \
            ..
        make -j"$(nproc)"
        make install
        cd ..

        cp "${LICENSE_FILE}" "${ARTIFACT_DIR}/LICENSE"
        _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}"
        generate_artifact_manifest "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" \
            "${ARTIFACT_VERSION}" "${PACKAGE_URL}" "${LICENSE_SPDX}"
    fi
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

