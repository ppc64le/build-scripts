#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sentry-python
# Version       : 2.33.2
# Source repo   : https://github.com/getsentry/sentry-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sentry-python"
PACKAGE_VERSION="${1:-2.33.2}"
PACKAGE_URL="https://github.com/getsentry/sentry-python"
PYPI_NAME="sentry-sdk"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================

RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — install test dependencies and async plugin
# =============================================================================
pre_test() {
    log_info "Installing test dependencies from requirements-testing.txt"
    python -m pip install -r requirements-testing.txt
    log_info "Installing pytest-asyncio for async test support"
    python -m pip install pytest-asyncio
}

# =============================================================================
# CALLBACK: custom_test_command — run tests with known-failing deselects
# =============================================================================
custom_test_command() {
    # Deselected tests:
    #   test_max_value_length, test_trim_databag_breadth:
    #     SDK serializer injects a _meta key for truncation metadata but the event
    #     schema declares additionalProperties: False — jsonschema rejects it.
    #     Upstream version mismatch; not a ppc64le issue.
    #   test_span_origin:
    #     OSError — container network sandbox blocks outbound connections to example.com.
    log_info "Running sentry-python test suite"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        --deselect tests/test_serializer.py::test_max_value_length \
        --deselect tests/test_serializer.py::test_trim_databag_breadth \
        --deselect tests/integrations/stdlib/test_httplib.py::test_span_origin \
        tests/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

