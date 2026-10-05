#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pytest-aiohttp
# Version       : v1.0.5
# Source repo   : https://github.com/aio-libs/pytest-aiohttp
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pytest-aiohttp"
PACKAGE_VERSION="${1:-v1.0.5}"
PACKAGE_URL="https://github.com/aio-libs/pytest-aiohttp"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — pin pytest-asyncio<0.22 to retain the event_loop fixture
# (removed in 0.22) required by the loop and proactor_loop fixtures, and to avoid
# PytestDeprecationWarning raised as INTERNALERROR in pytester subprocess tests
# =============================================================================
pre_test() {
    log_info "Pinning pytest-asyncio<0.22 to retain event_loop fixture and fix pytester subprocess tests"
    python -m pip install "pytest-asyncio<0.22"
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest in isolated mode with importlib to
# prevent local source dir from shadowing the installed wheel
# =============================================================================
custom_test_command() {
    log_info "Running tests in isolated mode with importlib import"
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        tests/ \
        --disable-warnings -v
}
# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

