#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyhdf
# Version       : v0.11.6
# Source repo   : https://github.com/fhs/pyhdf
# Tested on     : UBI:9.6
# Language      : C,Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyhdf"
PACKAGE_VERSION="${1:-v0.11.6}"
PACKAGE_URL="https://github.com/fhs/pyhdf"

# =============================================================================
# Artifact Dependencies (sourced automatically before build)
# =============================================================================
BUILD_DEPS="hdf4"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make python3-devel python3-pip zlib-devel libjpeg-devel"
DEB_DEP_PKGS="git gcc g++ make python3-dev python3-pip python3-venv zlib1g-dev libjpeg-dev"
SLES_DEP_PKGS="git gcc gcc-c++ make python3-devel python3-pip zlib-devel libjpeg-devel"

# =============================================================================
# CALLBACK: post_clone — patch setup.py for HDF4 4.3.0 library rename (df → hdf)
# =============================================================================
# HDF4 4.3.0 renamed libdf to libhdf; the symlink creation for libdf.so was
# removed from CMake install rules (commented out in hdf/src/CMakeLists.txt).
# pyhdf's setup.py hardcodes libraries=["mfhdf", "df"] — patch it to use "hdf".
post_clone() {
    log_info "Patching setup.py for HDF4 4.3.0 library rename (libdf → libhdf)"
    sed -i 's/libraries = \["mfhdf", "df"\]/libraries = ["mfhdf", "hdf"]/' setup.py
}

# =============================================================================
# CALLBACK: pre_build - source hdf4 artifact, set HDF4 paths, install build deps
# =============================================================================
pre_build() {
    log_info "Sourcing hdf4 artifact to get HDF4_PREFIX"
    source_artifact hdf4 || {
        log_error "hdf4 artifact not found — build hdf4 first"
        return 1
    }
    log_info "  HDF4_PREFIX=${HDF4_PREFIX:-unset}"

    log_info "Configuring HDF4 paths for pyhdf build"
    export INCLUDE_DIRS="${HDF4_PREFIX}/include"
    export LIBRARY_DIRS="${HDF4_PREFIX}/lib"

    log_info "Installing build dependencies"
    python -m pip install "numpy<2.0" setuptools-scm
}

# =============================================================================
# CALLBACK: custom_test_command - source hdf4 artifact for runtime, run examples
# =============================================================================
custom_test_command() {
    log_info "Sourcing hdf4 artifact for runtime library linking"
    source_artifact hdf4

    log_info "Installing test dependencies"
    python -m pip install "numpy<2.0"

    log_info "Running example scripts"
    if [[ -f "examples/runall.py" ]]; then
        python examples/runall.py
    else
        log_warn "examples/runall.py not found, skipping example tests"
    fi
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
