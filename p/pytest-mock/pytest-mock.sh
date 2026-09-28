#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pytest-mock
# Version       : v3.15.1
# Source repo   : https://github.com/pytest-dev/pytest-mock
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pytest-mock"
PACKAGE_VERSION="${1:-v3.15.1}"
PACKAGE_URL="https://github.com/pytest-dev/pytest-mock"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install setuptools-scm[toml] which pytest-mock uses as
# its build backend (missing from the venv by default, causes build failure)
# =============================================================================
pre_build() {
    log_info "Installing setuptools-scm[toml] build backend for pytest-mock"
    python -m pip install "setuptools-scm[toml]"
}

# =============================================================================
# CALLBACK: pre_test — install build backend and test-time dependencies:
#   - setuptools-scm[toml]: mirrors pre_build() — .venv-test is a fresh env
#   - pytest-asyncio: required for async spy and introspection tests
#   - mock: required by test_pytest_mock.py import (skipped without it)
# =============================================================================
pre_test() {
    log_info "Installing build backend and test dependencies for pytest-mock"
    python -m pip install pytest-asyncio mock
}

# =============================================================================
# CALLBACK: custom_test_command — deselect 2 introspection tests that reference
# _pytest.assertion.util._compare_eq_iterable, a private API removed from the
# pytest version shipped on UBI:9.6 (RHEL 9.8); this affects both v3.14.1 and
# v3.15.1 — the failure is an environment incompatibility, not a ppc64le issue.
# Pass asyncio_mode=auto so pytester subprocess tests do not emit the
# "Unknown config option: asyncio_mode" warning that breaks their fnmatch checks
# =============================================================================
custom_test_command() {
    log_info "Running pytest-mock tests"
    # _compare_eq_iterable removed from _pytest.assertion.util in the pytest version on UBI:9.6
    python -m pytest \
        -o "asyncio_mode=auto" \
        --disable-warnings \
        --deselect tests/test_pytest_mock.py::test_assert_called_args_with_introspection \
        --deselect tests/test_pytest_mock.py::test_assert_called_kwargs_with_introspection
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

