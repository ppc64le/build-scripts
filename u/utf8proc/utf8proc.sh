#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : utf8proc
# Version       : v2.6.1
# Source repo   : https://github.com/JuliaStrings/utf8proc
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="utf8proc"
PACKAGE_VERSION="${1:-v2.6.1}"
PACKAGE_URL="https://github.com/JuliaStrings/utf8proc"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="utf8proc"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git cmake make"
DEB_DEP_PKGS="git cmake make"
SLES_DEP_PKGS="git cmake make"

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_FILE="LICENSE.md"
LICENSE_SPDX="MIT"
SKIP_TESTS=true

# =============================================================================
# CALLBACK: custom_install — build and install utf8proc artifact with validation
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    # Validate existing artifact — env.sh alone is not enough
    if [[ -f "${ARTIFACT_DIR}/env.sh" && -f "${ARTIFACT_DIR}/include/utf8proc.h" ]]; then
        log_info "utf8proc artifact already exists at ${ARTIFACT_DIR}"
    else
        if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
            log_warn "utf8proc artifact at ${ARTIFACT_DIR} is missing headers — rebuilding"
            rm -rf "${ARTIFACT_DIR}"
        fi

        mkdir -p "${ARTIFACT_DIR}"

        local generator="Unix Makefiles"
        command -v ninja >/dev/null 2>&1 && generator="Ninja"

        mkdir -p build && cd build
        log_info "Configuring cmake for utf8proc"
        cmake -G "${generator}" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
            -DBUILD_SHARED_LIBS=ON \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            ..

        log_info "Building utf8proc"
        cmake --build . --parallel "$(nproc)"

        log_info "Installing utf8proc"
        cmake --install .
        cd ..

        cp "${LICENSE_FILE}" "${ARTIFACT_DIR}/LICENSE"
        _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}"
        generate_artifact_manifest "${ARTIFACT_DIR}" \
            "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}" \
            "${PACKAGE_URL}" "${LICENSE_SPDX}"

        log_info "utf8proc installed to ${ARTIFACT_DIR}"
    fi
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

