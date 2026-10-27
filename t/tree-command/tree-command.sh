#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tree-command
# Version       : upstream/2.0.2
# Source repo   : https://github.com/nodakai/tree-command
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tree-command"
PACKAGE_VERSION="${1:-upstream/2.0.2}"
PACKAGE_URL="https://github.com/nodakai/tree-command"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="tree-command"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc make"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_install - plain Makefile; install binary manually
# tree-command's Makefile has no PREFIX/DESTDIR support so we compile and
# copy the binary into the artifact directory ourselves.
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    mkdir -p "${ARTIFACT_DIR}/bin"

    log_info "Building tree binary"
    make -j"$(nproc)"

    log_info "Installing tree binary to ${ARTIFACT_DIR}/bin"
    cp -p tree "${ARTIFACT_DIR}/bin/tree"

    _copy_license "${ARTIFACT_DIR}"
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}"
}

# =============================================================================
# CALLBACK: post_build - generate env.sh for the artifact
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}"
}

# =============================================================================
# CALLBACK: custom_test_command - verify the installed binary
# =============================================================================
custom_test_command() {
    source "$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")/env.sh"
    log_info "Verifying tree binary"
    tree --version
}

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="GPL-2.0-or-later"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"
