#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sqlite-vec
# Version       : v0.1.9
# Source repo   : https://github.com/asg017/sqlite-vec
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sqlite-vec"
PACKAGE_VERSION="${1:-v0.1.9}"
PACKAGE_URL="https://github.com/asg017/sqlite-vec"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make gettext unzip python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — vendor C deps, build vec0.so, scaffold Python package.
# =============================================================================
post_clone() {
    log_info "Vendoring C dependencies for sqlite-vec..."
    ./scripts/vendor.sh

    log_info "Building sqlite-vec native extension (dist/vec0.so)..."
    make loadable

    log_info "Build output:"
    ls -l dist/

    local PKG_VER_CLEAN="${PACKAGE_VERSION#v}"

    log_info "Creating local/sqlite_vec Python package layout..."
    mkdir -p local/sqlite_vec
    cp dist/vec0.so local/sqlite_vec/
    cp bindings/python/extra_init.py local/sqlite_vec/__init__.py

    log_info "Preparing pyproject.toml (version ${PKG_VER_CLEAN})..."
    sed "s/{PACKAGE_VERSION}/${PKG_VER_CLEAN}/g" "${SCRIPT_DIR}/pyproject.toml" > pyproject.toml
}

# =============================================================================
# CALLBACK: pre_test — install test-only deps (pytest/setuptools via template).
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."
    python -m pip install numpy syrupy
}

# =============================================================================
# CALLBACK: custom_test_command — run upstream pytest suite.
# --rootdir=. prevents pytest picking up tests/pyproject.toml as configfile,
# which would break --deselect node ID matching.
# Deselected:
#   test_vec_npy_each_errors_files — uses delete_on_close (Python 3.12+ only)
#   test_idxstr                    — SQLite version difference in EQP output
# =============================================================================
custom_test_command() {
    log_info "Running sqlite-vec Python test suite..."
    python -m pytest \
        --rootdir=. \
        -p no:cacheprovider \
        tests/test-loadable.py \
        tests/test-general.py \
        tests/test-auxiliary.py \
        tests/test-insert-delete.py \
        tests/test-knn-distance-constraints.py \
        tests/test-metadata.py \
        tests/test-partition-keys.py \
        -o "addopts=" \
        --disable-warnings \
        --deselect tests/test-loadable.py::test_vec_npy_each_errors_files \
        --deselect tests/test-metadata.py::test_idxstr \
        -v
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"

