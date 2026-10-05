#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : opentelemetry-python
# Version       : v1.37.0
# Source repo   : https://github.com/open-telemetry/opentelemetry-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="opentelemetry-python"
PACKAGE_VERSION="${1:-v1.37.0}"
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-python"

# The monorepo publishes individual packages to PyPI; the top-level repo name
# does not exist as a PyPI package. Install the two canonical packages.
NOARCH="true"
PYPI_NAME="opentelemetry-api"

# =============================================================================
# REQUIRED: Dependencies
# Pure Python — git only needed for cloning the test suite.
# =============================================================================
RH_DEP_PKGS="git python3 python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test
# Runs inside the test venv after the template installs opentelemetry-api.
# Install the remaining core packages and opentelemetry-test-utils (not on
# PyPI — installed as an editable local install from the cloned source).
# =============================================================================
pre_test() {
    local ver="${PACKAGE_VERSION#v}"

    # opentelemetry-sdk pulls in opentelemetry-semantic-conventions (0.x)
    python -m pip install \
        "opentelemetry-sdk==${ver}" \
        "opentelemetry-proto==${ver}"

    # test-utils lives only in the monorepo — not published to PyPI
    python -m  pip install -e tests/opentelemetry-test-utils

    # test-only deps not covered by the packages above
    python -m pip install flaky psutil wrapt
}

# =============================================================================
# CALLBACK: custom_test_command
# Run the API and SDK test suites from the cloned monorepo.
# All packages and test deps are already installed by pre_test above.
# =============================================================================
custom_test_command() {
    log_info "Running opentelemetry-api tests..."
    if ! python -m pytest opentelemetry-api/tests/ -x -q; then
        log_error "opentelemetry-api tests failed"
        return 1
    fi

    log_info "Running opentelemetry-sdk tests..."
    if ! python -m pytest opentelemetry-sdk/tests/ -x -q; then
        log_error "opentelemetry-sdk tests failed"
        return 1
    fi
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

