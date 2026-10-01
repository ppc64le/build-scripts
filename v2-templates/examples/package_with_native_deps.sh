#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : example-with-native-deps
# Version       : 1.0.0
# Source repo   : https://github.com/example/package
# Tested on     : UBI:9.3
# Language      : Python, C++
# Script License: Apache License, Version 2 or later
# Maintainer    : Your Name <your.email@example.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution.
#
# Notes:
#   - This is an EXAMPLE script demonstrating the native dependency pattern
#   - Shows how to use pre-built native C/C++ dependencies (artifacts)
#   - See templates/docs/NATIVE_DEPENDENCIES.md for full documentation
#
# Complexity: Level 4 (native dependencies)
#   - Requires protobuf built from source
#   - Uses artifact system for dependency management
#   - Includes license collection for wheel compliance
#
# Dependencies declared in TWO places (for stage isolation):
#   1. build_info.json (preprocessor reads this for tsort):
#      { "build_deps": ["protobuf:v25.3"] }
#   2. Shell variables below (runtime, triggers artifacts.sh):
#      BUILD_DEPS="protobuf:v25.3"
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="example-package"
PACKAGE_VERSION="${1:-1.0.0}"
PACKAGE_URL="https://github.com/example/package"

# =============================================================================
# Artifact Declaration (runtime)
# These variables trigger templates/lib/artifacts.sh to be sourced.
# The same values should also be in build_info.json for the preprocessor.
# =============================================================================
BUILD_DEPS="protobuf:v25.3"

# =============================================================================
# REQUIRED: System dependencies
# These are installed via package manager before the build
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip cmake ninja-build"
DEB_DEP_PKGS="git gcc g++ python3-dev python3-pip python3-venv cmake ninja-build"
SLES_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip cmake ninja"

# =============================================================================
# CALLBACK: pre_build
# Source native dependencies before Python build
#
# This runs INSIDE .venv-build, so pip install works correctly.
# The pattern is:
#   1. Source required artifacts (built by dependency scripts)
#   2. Verify the artifact is usable
#   3. Install Python build dependencies
# =============================================================================
pre_build() {
    # Source required artifacts
    # The artifact system looks in ARTIFACT_WORKSPACE (set by execution engine)
    if ! source_artifact protobuf; then
        log_error "protobuf artifact not found!"
        log_error "Build protobuf first: p/protobuf/protobuf.sh"
        return 1
    fi

    # Verify dependency is available
    if ! command -v protoc &>/dev/null; then
        log_error "protoc not found after sourcing artifact"
        return 1
    fi
    log_info "Using protoc: $(protoc --version)"

    # Install Python build dependencies
    pip install numpy pybind11 protobuf
}

# =============================================================================
# CALLBACK: post_build (optional)
# Collect licenses after build, before wheel creation
#
# This ensures all native dependency licenses are included in the wheel
# for PyPA compliance and auditwheel validation.
# =============================================================================
post_build() {
    log_info "Collecting dependency licenses..."

    # Create licenses directory in package
    local license_dir="${PWD}/licenses"
    mkdir -p "${license_dir}"

    # Collect all artifact licenses
    collect_dependency_licenses "${license_dir}"

    # Verify collection
    if [[ -f "${license_dir}/THIRD_PARTY_LICENSES.txt" ]]; then
        log_info "License collection complete"
    else
        log_warn "No third-party licenses collected (may be OK if no artifacts used)"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command (optional)
# Run tests with native libraries available
# =============================================================================
custom_test_command() {
    # Ensure native libraries are in path for tests
    source_artifact protobuf || true

    log_info "Running tests..."
    pytest -v tests/ --disable-warnings || return $?
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
