#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sympy
# Version       : sympy-1.13.0
# Source repo   : https://github.com/sympy/sympy
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sympy"
PACKAGE_VERSION="${1:-sympy-1.13.0}"
PACKAGE_URL="https://github.com/sympy/sympy"

# PyPI verified: all wheels for sympy are py3-none-any (pure Python, no compiled extensions)
# https://pypi.org/pypi/sympy/1.13.0/json
NOARCH="true"
PYPI_VERSION="1.13.0"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install hypothesis required by sympy/conftest.py
# =============================================================================
pre_test() {
    log_info "Installing hypothesis required by ${PACKAGE_NAME}/conftest.py"
    python -m pip install hypothesis
}

# =============================================================================
# CALLBACK: custom_test_command — run integrals tests only, skip test_manual.py
# Test cases live under <repo>/<PACKAGE_NAME>/integrals/tests/
# test_manual.py is excluded: it requires a live network/CAS backend not
# available in CI and causes long hangs on ppc64le.
# =============================================================================
custom_test_command() {
    log_info "Running ${PACKAGE_NAME} integrals tests"
    # Tests located at ${PACKAGE_NAME}/integrals/tests/ inside the cloned repo
    python -m pytest -p no:warnings \
        --ignore="${PACKAGE_NAME}/integrals/tests/test_manual.py" \
        -W ignore::DeprecationWarning \
        "${PACKAGE_NAME}/integrals/tests/"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

