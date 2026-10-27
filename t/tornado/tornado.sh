#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tornado
# Version       : v6.4.2
# Source repo   : https://github.com/tornadoweb/tornado
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <ich@us.ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tornado"
PACKAGE_VERSION="${1:-v6.4.2}"
PACKAGE_URL="https://github.com/tornadoweb/tornado"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ libcurl-devel openssl-devel python3-devel"
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
# CALLBACK: pre_build — install build-time dependencies for C extension compilation
# =============================================================================
pre_build() {
    log_info "Installing build backend dependencies for tornado C extensions"
    python -m pip install --upgrade pip setuptools wheel
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into the isolated test venv
# =============================================================================
pre_test() {
    log_info "Installing build backend into test venv"
    python -m pip install --upgrade pip setuptools wheel

    log_info "Installing optional test dependencies (pycares, twisted, pycurl)"
    python -m pip install "pycares<5" "twisted<24.7" pycurl || true
}

# =============================================================================
# CALLBACK: custom_test_command — run tornado's built-in test suite via pytest
# Legacy v1 script used: python3 -m tox -e py39
# Replaced with pytest discovery for deselect support
# tornado's requirements.txt pins tox==4.6.0 which pulls in pluggy==1.0.0;
# the template installs requirements.txt after pre_test(), which downgrades
# pluggy and breaks pytest>=8 (ImportError: cannot import name 'HookimplOpts');
# tox is uninstalled here (after requirements.txt is applied) and pluggy is
# re-pinned to a version compatible with pytest>=8 before running tests
# test_source_port_fail: deselected because binding to privileged port 1 does
# not raise OSError in the ppc64le CI environment (non-root user with
# CAP_NET_BIND_SERVICE or equivalent kernel capability active), causing the
# assertRaises(OSError) assertion to fail
# =============================================================================
custom_test_command() {
    log_info "Removing tox and re-pinning pluggy to fix HookimplOpts ImportError"
    python -m pip uninstall -y tox pytest-cov pytest-xdist 2>/dev/null || true
    python -m pip install --upgrade "pluggy>=1.5"

    log_info "Running tornado test suite"
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --deselect tornado/test/tcpclient_test.py::TCPClientTest::test_source_port_fail \
        tornado/test/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
