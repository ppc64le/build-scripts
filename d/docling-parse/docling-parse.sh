#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : docling-parse
# Version       : v6.2.0
# Source repo   : https://github.com/docling-project/docling-parse
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Adarsh Agrawal <adarsh.agrawal1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="docling-parse"
PACKAGE_VERSION="${1:-v6.2.0}"
PACKAGE_URL="https://github.com/docling-project/docling-parse"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake freetype-devel gcc gcc-c++ git libjpeg-devel libjpeg-turbo libjpeg-turbo-devel python3-devel python3-pip wget zlib zlib-devel"
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
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install build-time dependencies from pyproject.toml
# =============================================================================
# docling-parse uses a custom CMake/pybind11 build (setup.py delegates to
# local_build.py which calls cmake). Because the template builds with
# --no-isolation, all [build-system].requires must be installed in .venv-build.
# tomli is required to parse pyproject.toml on Python < 3.11.
pre_build() {
    log_info "Installing tomli for pyproject.toml parsing"
    python -m pip install tomli

    if [[ -f "pyproject.toml" ]]; then
        log_info "Extracting and installing build-system requirements from pyproject.toml"
        python -c "
import tomli, subprocess, sys
with open('pyproject.toml', 'rb') as f:
    requires = tomli.load(f)['build-system']['requires']
subprocess.run([sys.executable, '-m', 'pip', 'install'] + requires, check=True)
"
    else
        log_info "pyproject.toml not found — installing fallback build deps"
        python -m pip install pybind11
    fi

    log_info "Installing setuptools-scm for version detection"
    python -m pip install setuptools-scm
}

# =============================================================================
# CALLBACK: pre_test — install test deps and mirror build deps into test venv
# =============================================================================
# .venv-test is a fresh venv that does not inherit from .venv-build.
# setuptools, wheel, and pybind11 must be re-installed here so the wheel
# installed into .venv-test resolves correctly. huggingface-hub is imported
# by tests/conftest.py but is not declared in the package's test requirements.
pre_test() {
    log_info "Installing base build deps into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install pybind11

    log_info "Installing test-only dependencies"
    python -m pip install "huggingface-hub>=1.11.0"
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest with importlib mode to prevent
# source-tree shadowing of the compiled pdf_parsers C++ extension
# =============================================================================
# docling-parse builds a pybind11 C++ extension (pdf_parsers.so) that is
# installed into site-packages/docling_parse/. When pytest runs from the clone
# root, Python's sys.path includes the source tree's docling_parse/ directory,
# which shadows the installed package and causes:
#   ModuleNotFoundError: No module named 'docling_parse.pdf_parsers'
#
# --import-mode=importlib combined with -I (isolated mode) prevents the source
# directory from appearing on sys.path, so the installed .so is found instead.
custom_test_command() {
    log_info "Running tests with importlib import mode to resolve C extension shadowing"
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        tests/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
