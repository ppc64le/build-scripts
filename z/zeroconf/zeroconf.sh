#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : zeroconf
# Version       : 0.151.5
# Source repo   : https://github.com/python-zeroconf/python-zeroconf
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM Power Engineering <power@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="zeroconf"
PACKAGE_VERSION="${1:-0.151.5}"
PACKAGE_URL="https://github.com/python-zeroconf/python-zeroconf"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc python3-devel"
DEB_DEP_PKGS="git gcc python3-dev python3-venv"
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
# CALLBACK: pre_build — install Cython and poetry-core build dependencies
# =============================================================================
pre_build() {
    log_info "Installing Cython and poetry-core required to build zeroconf C extensions"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "Cython>=3.0.8" "poetry-core>=2.1.0"
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into the test venv
# =============================================================================
pre_test() {
    log_info "Installing build backend and Cython into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "Cython>=3.0.8" "poetry-core>=2.1.0"
    log_info "Installing test-only dependencies"
    python -m pip install pytest-asyncio pytest-timeout pytest-codspeed ifaddr
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest, clearing coverage addopts and
#   removing pytest-cov that crashes before -p flags are processed
# =============================================================================
custom_test_command() {
    log_info "Uninstalling pytest-cov which crashes via entrypoints before -p flags are processed"
    python -m pip uninstall -y pytest-cov 2>/dev/null || true

    log_info "Running zeroconf test suite"
    python -m pytest \
        -o "addopts=" \
        --import-mode=importlib \
        --disable-warnings \
        --timeout=60 \
        --deselect tests/services/test_types.py::test_integration_with_listener_ipv6 \
        tests/
    # test_integration_with_listener_ipv6: requires routable IPv6 multicast (ff02::fb);
    # CI containers have loopback-only IPv6 so sendto returns ENETUNREACH (errno 101).
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
