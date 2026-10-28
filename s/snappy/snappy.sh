#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : snappy
# Version       : 1.2.2
# Source repo   : https://github.com/google/snappy
# Tested on     : UBI:9.6
# Language      : c++
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="snappy"
PACKAGE_VERSION="${1:-1.2.2}"
PACKAGE_URL="https://github.com/google/snappy"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="snappy"
ARTIFACT_VERSION="${PACKAGE_VERSION#v}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git cmake make python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_WHEEL="true"
LICENSE_FILE="COPYING"
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# CALLBACK: custom_install — compiles libsnappy via cmake and prepares Python wheel layout
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    if [[ ! -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Compiling native snappy library..."
        # Create the artifact staging dir and an out-of-source build dir so that
        # cmake-generated files do not pollute the cloned source tree.
        mkdir -p "${ARTIFACT_DIR}" cmake-build
        cd cmake-build

        # Configure: build a shared library (.so), enable the bundled unit-test
        # binary, and install everything under ARTIFACT_DIR/lib (not lib64) so
        # the Python wheel layout below can use a single fixed path.
        cmake \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
            -DBUILD_SHARED_LIBS=ON \
            -DSNAPPY_BUILD_TESTS=ON \
            -DCMAKE_INSTALL_LIBDIR=lib \
            ..
        make -j"$(nproc)"
        make install
        cd ..

        # Export LD_LIBRARY_PATH so auditwheel can find the compiled shared libraries to repair the wheel
        export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${LD_LIBRARY_PATH:-}"

        # Prepare the Python packaging layout with all installed libraries,
        # shared files, and headers, including benchmark/gtest/gmock artifacts.
        mkdir -p local/snappy/lib local/snappy/share local/snappy/include
        touch local/snappy/__init__.py
        cp -a "${ARTIFACT_DIR}"/lib/. local/snappy/lib/
        cp -a "${ARTIFACT_DIR}"/share/. local/snappy/share/
        cp -a "${ARTIFACT_DIR}"/include/. local/snappy/include/

        # Copy pyproject.toml from the script directory and replace the version placeholder
        log_info "Preparing pyproject.toml..."
        if [[ -f "${SCRIPT_DIR}/pyproject.toml" ]]; then
            sed "s/{PACKAGE_VERSION}/${PACKAGE_VERSION}/g" "${SCRIPT_DIR}/pyproject.toml" > pyproject.toml
        else
            log_error "Static pyproject.toml template not found in ${SCRIPT_DIR}"
            false
        fi
    else
        log_info "Artifact already exists at ${ARTIFACT_DIR}. Skipping entire build."
    fi
}

# =============================================================================
# CALLBACK: post_build — packages the artifact environment, license, and manifest
# =============================================================================
post_build() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}")"

    # Remove any intermediate build artefacts from the staging dir (object files,
    # cmake cache, etc.) so that only the final installed files are packaged.
    _cleanup_artifact "${ARTIFACT_DIR}"
    # Copy the upstream LICENSE file (COPYING) into the artifact dir so it is
    # included in the wheel and satisfies distribution requirements.
    _copy_license "${ARTIFACT_DIR}"
    # Write env.sh — sourced by downstream consumers to set LD_LIBRARY_PATH,
    # CPATH, and PKG_CONFIG_PATH to point at this artifact's installed files.
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}"
    # Produce the JSON manifest consumed by the artifact registry to record what
    # version of snappy was built, where it came from, and its SPDX license tag.
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}"
}

# =============================================================================
# CALLBACK: custom_test_command — run the C++ snappy unit tests
# =============================================================================
custom_test_command() {
    log_info "Running snappy C++ unit tests"
    # Run from clone root so the binary finds testdata/ in the source tree
    ./cmake-build/snappy_unittest
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
