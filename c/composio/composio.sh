#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : composio
# Version       : 0.16.0
# Source repo   : https://github.com/composiohq/composio
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : tharun.sj@ibm.com
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="composio"
PACKAGE_VERSION="${1:-py@0.16.0}"
PACKAGE_URL="https://github.com/composiohq/composio"

# Pure-Python package — wheel is py3-none-any; install from PyPI
NOARCH="true"
# GitHub tag uses "py@" prefix; strip it to get the bare PyPI version (e.g. py@0.16.0 → 0.16.0)
PYPI_VERSION="${PACKAGE_VERSION#py@}"
PYPI_VERSION="${PYPI_VERSION#v}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command — run only the core python/tests/ suite.
# Ignored files require a live COMPOSIO_API_KEY (test_type_inference*.py) or
# an optional provider not installed in the CI venv (TestLangchainReservedKeywords).
# --ignore works on whole files; -k excludes the class within test_provider.py.
# =============================================================================
custom_test_command() {
    log_info "Running composio core tests"
    python -m pytest \
        python/tests/ \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --ignore=python/tests/test_type_inference.py \
        --ignore=python/tests/test_type_inference_custom_provider.py \
        -k "not TestLangchainReservedKeywords"  # requires langchain-core, not installed in CI venv
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
