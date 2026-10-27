#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : itsdangerous
# Version       : 2.2.0
# Source repo   : https://github.com/pallets/itsdangerous
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="itsdangerous"
PACKAGE_VERSION="${1:-2.2.0}"
PACKAGE_URL="https://github.com/pallets/itsdangerous"
NOARCH="true"
# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install flit_core build backend required by pyproject.toml
# =============================================================================
# itsdangerous uses flit_core as its build backend. Because the template builds
# with --no-isolation, flit_core must be present in the build venv or the build
# fails with "Backend 'flit_core.buildapi' is not available".
# Only 2.2.0+ ships pyproject.toml; 2.1.2 uses setup.cfg and does not need this.
pre_build() {
    if [[ -f "pyproject.toml" ]]; then
        log_info "Installing flit_core build backend (required by pyproject.toml)"
        python -m pip install "flit_core<4"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest directly, bypassing tox
# =============================================================================
# For 2.1.2: tox.ini targets py3{7..11} with no generic py3 env and installs
# pytest==7.0.1 (pinned in requirements/tests.txt), which crashes on Python 3.12
# due to "DeprecationWarning: ast.Str is deprecated" being raised as an error
# during assertion rewriting. Running pytest directly with a fresh install avoids
# the stale tox env and the incompatible pinned pytest.
custom_test_command() {
    log_info "Installing test dependencies"
    python -m pip install "pytest>=8" freezegun

    log_info "Running pytest"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        tests/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
