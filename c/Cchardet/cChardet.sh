#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cChardet
# Version       : v2.4.0
# Source repo   : https://github.com/PyYoshi/cChardet
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cChardet"
PACKAGE_VERSION="${1:-v2.4.0}"
PACKAGE_URL="https://github.com/PyYoshi/cChardet"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-c++"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — read setuptools requirement from pyproject.toml
# =============================================================================
post_clone() {
    log_info "Reading setuptools version requirement from pyproject.toml"
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
        # No pyproject.toml present — fall back to a safe upper bound
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install Cython and pre-generate C++ source from .pyx
# cChardet's setup.py lists Cython as a build-system requirement but does
# not declare it in pyproject.toml build-system.requires, so pip's
# build-isolation step does not install it automatically. Install it
# explicitly here so that `python -m build --no-isolation` can invoke
# the Cython transpiler on src/cchardet/_cchardet.pyx.
# The --cplus flag is required because setup.py declares language="c++"
# for the extension; without it Cython emits a .c file that the C++
# compiler rejects.
# =============================================================================
pre_build() {
    log_info "Installing Cython build dependency"
    python -m pip install "cython>=3.0.10"

    log_info "Generating C++ source from .pyx"
    python -m cython -3 src/cchardet/_cchardet.pyx --cplus
}

# =============================================================================
# CALLBACK: pre_test — install build backend and test dependencies
# =============================================================================
pre_test() {
    log_info "Installing build backend and test dependencies into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "cython>=3.0.10" pytest chardet charset-normalizer
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest on tests directory
# In v2.4.0, test files are located in tests/ (test_1.py, test_accuracy.py,
# test_cli.py, test_robustness.py, test_typing.py). Run pytest directly on
# the tests/ directory.
# =============================================================================
custom_test_command() {
    log_info "Running cChardet tests"
    python -m pytest tests/ -o "addopts=" --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"