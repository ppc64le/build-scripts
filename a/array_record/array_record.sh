#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : array_record
# Version       : v0.8.3
# Source repo   : https://github.com/google/array_record
# Tested on     : UBI:9.6
# Language      : Python, C++
# Script License: Apache License, Version 2 or later
# Maintainer    : Pooja Shah <Pooja.Shah4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="array_record"
PACKAGE_VERSION="${1:-v0.8.3}"
PACKAGE_URL="https://github.com/google/array_record"

# =============================================================================
# Build dependencies (loaded automatically by python.sh from build_info.json)
# =============================================================================
# The bazel version per package version is defined in build_info.json;
# the value below is only the fallback for local runs.
BUILD_DEPS="${BUILD_DEPS:-bazel:7.4.1}"

# Skip template's test phase - build_whl.sh handles both build and test
SKIP_TESTS="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make cmake gcc gcc-c++ zip unzip tar wget rsync patch jq python3-devel python3-pip java-21-openjdk-devel zlib-devel openssl-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone
# Initialize submodules and apply patches
# =============================================================================
post_clone() {
    log_info "Initializing submodules..."
    git submodule update --init --recursive
    
    log_info "Applying patch for ${PACKAGE_VERSION}..."
    PATCH_FILE="${SCRIPT_DIR}/patches/array_record_${PACKAGE_VERSION}.patch"
    
    if [[ -f "${PATCH_FILE}" ]]; then
        log_info "Found patch file: ${PATCH_FILE}"
        if ! git apply "${PATCH_FILE}"; then
            log_error "Failed to apply patch: ${PATCH_FILE}"
        fi
        log_info "Patch applied successfully"
    else
        log_warn "No patch file found for version ${PACKAGE_VERSION}"
        log_warn "Expected: ${PATCH_FILE}"
    fi
}

# =============================================================================
# CALLBACK: pre_build
# Install Python modules needed by setup.py and the import smoke tests
# =============================================================================
pre_build() {
    log_info "Installing array_record Python dependencies"
    python -m pip install etils typing_extensions importlib_resources absl-py
}

# =============================================================================
# CALLBACK: custom_install
# Build package & wheel using the build_whl.sh script
# =============================================================================
# Hooks run under `if !`, which disables `set -e`; the && chain makes the first
# failing command the hook's exit status. The patched build_whl.sh writes the
# wheel to array_record/dist; it is copied to dist/ for the template to package.
# The Bazel server is shut down at the end so its memory is released before the
# template's wheel post-processing (the container was OOM-killed at the 8g limit).
custom_install() {
    export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
    export PATH="${JAVA_HOME}/bin:${PATH}"
    export CURRENT_DIR="${PWD}"
    export PYTHON_BIN
    PYTHON_BIN="$(command -v python)"

    local py_version py_minor
    py_version="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
    py_minor="${py_version#*.}"

    log_info "Building array_record ${PACKAGE_VERSION} with Bazel (Python ${py_version}) via oss/build_whl.sh"
    PYTHON_VERSION="${py_version}" PYTHON_MINOR_VERSION="${py_minor}" bash oss/build_whl.sh &&
    log_info "Copying built wheel to dist/" &&
    mkdir -p dist &&
    cp array_record/dist/*.whl dist/ &&
    log_info "Shutting down Bazel server to release memory" &&
    bazel shutdown
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"