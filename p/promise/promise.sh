#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : promise
# Version       : v2.3.0
# Source repo   : https://github.com/syrusakbary/promise
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="promise"
PACKAGE_VERSION="${1:-v2.3.0}"
PACKAGE_URL="https://github.com/syrusakbary/promise"

NOARCH="true"
# PyPI version differs from the GitHub tag (v2.3.0 -> 2.3 on PyPI)
PYPI_VERSION="${PYPI_VERSION:-2.3}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install pytest-asyncio and pytest-benchmark for test suite
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install pytest-asyncio pytest-benchmark
}

# =============================================================================
# CALLBACK: custom_test_command — skip tests incompatible with modern Python/pytest
# =============================================================================
custom_test_command() {
    log_info "Running promise tests"
    # test_awaitable.py: legacy @asyncio.coroutine/yield breaks collection on Python 3.10+
    # test_thrown_exceptions_*: use removed py.path .strpath API in newer pytest
    # test_issue_9_safe: async def test not handled by pytest-asyncio in this context
    python -m pytest \
        --ignore=tests/test_awaitable.py \
        --deselect=tests/test_extra.py::test_thrown_exceptions_have_stacktrace \
        --deselect=tests/test_extra.py::test_thrown_exceptions_preserve_stacktrace \
        --deselect=tests/test_issues.py::test_issue_9_safe \
        --disable-warnings \
        -o "addopts=" \
        -o "asyncio_mode=auto"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

