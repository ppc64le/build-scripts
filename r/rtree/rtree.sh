#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : rtree
# Version       : 1.4.1
# Source repo   : https://github.com/Toblerity/rtree
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
#
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="rtree"
PACKAGE_VERSION="${1:-1.4.1}"
PACKAGE_URL="https://github.com/Toblerity/rtree"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3-devel sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""


# =============================================================================
# CALLBACK: post_clone
# =============================================================================
post_clone() {

    log_info "Reading setuptools version from pyproject.toml"
    local setuptools_req
    setuptools_req="$(grep -o '"setuptools[><=!][^"]*"' pyproject.toml | head -1 | tr -d '"')"
    if [[ -n "${setuptools_req}" ]]; then
        SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
        SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
        log_info "Using setuptools${SETUPTOOLS_VERSION} (from pyproject.toml)"
    else
        log_info "setuptools not found in pyproject.toml, using template default"
    fi

    log_info "Running install_libspatialindex.sh script..."
    if [[ -f scripts/install_libspatialindex.sh ]]; then
        bash scripts/install_libspatialindex.sh
    else
        log_info "scripts/install_libspatialindex.sh not found, skipping."
    fi
}

# =============================================================================
# CALLBACK: pre_build
    # libspatialindex_c.so links against libspatialindex.so — both live in
    # rtree/lib/.  auditwheel must be able to find libspatialindex.so to bundle
    # it into the repaired wheel.
# =============================================================================
pre_build() {
    log_info "Setting LD_LIBRARY_PATH for auditwheel to locate libspatialindex.so"
    export LD_LIBRARY_PATH="$(pwd)/rtree/lib:${LD_LIBRARY_PATH:-}"
}

# =============================================================================
# CALLBACK: custom_install
   # The template's default: python -m build --no-isolation (no --wheel flag)
    # builds sdist first, then wheel FROM the sdist.  The sdist excludes
    # rtree/lib/*.so (not in MANIFEST.in or pyproject.toml package-data),
    # so the resulting wheel is pure-Python and auditwheel skips repair.
    #
    # --wheel builds directly from the source tree (no sdist intermediate),
    # so rtree/lib/*.so — already present after post_clone — ends up in the
    # wheel, exactly as when running the command manually from the clone dir.
# =============================================================================
custom_install() {
    log_info "Upgrading pip build tools and installing auditwheel"
    python -m pip install --upgrade pip build wheel pip-tools patchelf auditwheel
    log_info "Building wheel directly from source tree (bypassing sdist)"
    python -m build --wheel --no-isolation
}

# =============================================================================
# CALLBACK: pre_test
    # tox.ini uses --only-binary=:all: which prevents source builds on ppc64le;
    # remove it so dependencies can be built from source when needed.
# =============================================================================
pre_test() {
    log_info "Setting LD_LIBRARY_PATH for test runtime"
    export LD_LIBRARY_PATH="$(pwd)/rtree/lib:${LD_LIBRARY_PATH:-}"
    log_info "Installing test dependencies"
    python -m pip install numpy
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"