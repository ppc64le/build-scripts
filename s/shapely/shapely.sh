#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : shapely
# Version       : 2.0.6
# Source repo   : https://github.com/shapely/shapely
# Tested on     : UBI:9.6
# Language      : Python, C, Cython
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandan.Abhyankar@ibm.com
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="shapely"
PACKAGE_VERSION="${1:-2.0.6}"
PACKAGE_URL="https://github.com/shapely/shapely"

BUILD_DEPS="geos:3.12.1"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc-c++ gcc-gfortran cmake make python3-devel python3-pip openblas-devel openblas"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — read setuptools requirement from pyproject.toml
# =============================================================================
post_clone() {
    log_info "Reading setuptools version requirement from pyproject.toml"
    # Python 3.12 removed pkgutil.ImpImporter; setuptools < 67.3 crashes on import.
    # Override any old pin from pyproject.toml when running on Python 3.12+.
    py_minor="$(python -c 'import sys; print(sys.version_info.minor)')"
    if [[ "${py_minor}" -ge 12 ]]; then
        SETUPTOOLS_VERSION=">=67.3,<82"
        log_info "Python 3.12+ detected — forcing SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
        return
    fi
    if [[ -f "pyproject.toml" ]]; then
        setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
        if [[ -n "$setuptools_req" ]]; then
            SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
            SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
            log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
        else
            log_info "No setuptools pin found in pyproject.toml — using template default"
        fi
    else
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install Cython and numpy build dependencies
# =============================================================================
pre_build() {
    log_info "Installing Cython and numpy build dependencies..."
    if grep -q "Cython.*<3" pyproject.toml 2>/dev/null; then
        log_info "Detected Cython<3 requirement in pyproject.toml (shapely 1.x)"
        python -m pip install "cython<3,>=0.29.24" oldest-supported-numpy numpy
    else
        python -m pip install "cython>=3.0.0" numpy
    fi
}

# =============================================================================
# CALLBACK: pre_test — mirror pre_build dependencies into the test venv
# =============================================================================
pre_test() {
    log_info "Installing build backend deps for test venv..."
    python -m pip install --upgrade pip setuptools wheel
    if grep -q "Cython.*<3" pyproject.toml 2>/dev/null; then
        python -m pip install "cython<3,>=0.29.24" oldest-supported-numpy numpy
    else
        python -m pip install "cython>=3.0.0" numpy
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — run tests from installed package or top-level tests/
# =============================================================================
custom_test_command() {
    log_info "Running shapely tests..."
    # In shapely 2.x, tests are installed inside the package (shapely.tests).
    # In shapely 1.x, tests reside in the top-level tests/ directory.
    pkg_ver=(${PACKAGE_VERSION#v})
    pkg_ver=(${pkg_ver//./ })
    if [[ ${pkg_ver[0]} -ge 2 ]]; then
        log_info "Running shapely tests from installed package (shapely.tests)..."
        python -I -m pytest --pyargs shapely.tests \
            --import-mode=importlib \
            -o "addopts=" \
            --disable-warnings \
            -v
    else
        log_info "Running shapely tests from top-level tests/ directory..."
        # Deselect tests that fail due to GEOS >= 3.12 behaviour changes:
        #   test_create_inconsistent_dimensionality: GEOS 3.12 rejects mixed-dim WKT
        #   test_parallel_offset_linestring: corner join geometry changed in GEOS 3.11+
        #   test_edges: voronoi edges return MultiLineString in GEOS 3.12, not LineString
        python -m pytest tests/ \
            --import-mode=importlib \
            -o "addopts=" \
            --disable-warnings \
            --deselect tests/test_create_inconsistent_dimensionality.py \
            --deselect tests/test_parallel_offset.py::OperationsTestCase::test_parallel_offset_linestring \
            --deselect tests/test_voronoi_diagram.py::test_edges \
            -v
    fi
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
