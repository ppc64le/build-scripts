#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sphinx-autodoc-typehints
# Version       : 3.2.0
# Source repo   : https://github.com/tox-dev/sphinx-autodoc-typehints
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sphinx-autodoc-typehints"
PACKAGE_VERSION="${1:-3.2.0}"
PACKAGE_URL="https://github.com/tox-dev/sphinx-autodoc-typehints"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — install test dependencies into the test venv
# Pin sphinx<9 because Sphinx 9.x changed attribute type rendering (adds quotes)
# which breaks the test_integration expectations written against Sphinx 8.x
# =============================================================================
pre_test() {
    log_info "Installing test dependencies for ${PACKAGE_NAME}"
    python -m pip install ".[testing]" "sphinx>=8.2,<9"
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest directly (tox.ini requires tox-uv
# which is unavailable in the container; extras numpy/type-comment listed in
# tox.ini do not exist in pyproject.toml 3.2.0; tox env names are 3.11/3.12/3.13
# which do not match the template's py3 invocation)
# =============================================================================
custom_test_command() {
    log_info "Running pytest for ${PACKAGE_NAME}"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        tests
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

