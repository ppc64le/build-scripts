#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : fsspec
# Version       : 2026.4.0
# Source repo   : https://github.com/fsspec/filesystem_spec
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="fsspec"
PACKAGE_VERSION="${1:-2026.4.0}"
PACKAGE_URL="https://github.com/fsspec/filesystem_spec"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — create _version.py so conftest.py can import fsspec
# from the source tree without failing. hatchling generates this file at build
# time but it is absent from a raw git checkout.
# =============================================================================
post_clone() {
    log_info "Generating fsspec/_version.py for source-tree imports"
    echo "__version__ = \"${PACKAGE_VERSION}\"" > fsspec/_version.py
}

# =============================================================================
# CALLBACK: pre_test — install fsspec test extras into test venv
# =============================================================================
pre_test() {
    log_info "Installing fsspec test dependencies"
    python -m pip install --upgrade wheel
    python -m pip install aiohttp pytest-asyncio requests pytest-mock numpy
}

# =============================================================================
# CALLBACK: custom_test_command — run tests from within fsspec/tests/
# =============================================================================
custom_test_command() {
    log_info "Running fsspec tests"
    python -m pytest fsspec/tests/ \
        -o "addopts=" \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"