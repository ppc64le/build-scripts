#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : opentelemetry-python-contrib
# Version       : v1.16.0
# Source repo   : https://github.com/open-telemetry/opentelemetry-python-contrib
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="opentelemetry-python-contrib"
PACKAGE_VERSION="${1:-v1.16.0}"
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-python-contrib"

# The monorepo publishes individual contrib packages to PyPI; the top-level
# repo name does not exist as a PyPI package. Contrib packages use a 0.x beta
# versioning scheme independent of the git tag (v1.16.0 -> 0.37b0).
NOARCH="true"
PYPI_NAME="opentelemetry-instrumentation"
PYPI_VERSION="0.37b0"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test
# Runs inside the test venv after the template installs opentelemetry-instrumentation.
# Install the companion distro package and test-only deps.
# =============================================================================
pre_test() {
    # opentelemetry-distro bundles auto-instrumentation helpers tested here
    python -m pip install "opentelemetry-distro==${PYPI_VERSION}"

    # opentelemetry-test-utils provides opentelemetry.test used by the test suite
    python -m pip install "opentelemetry-test-utils==${PYPI_VERSION}"

    # test-only deps
    python -m pip install pytest-benchmark wrapt
}

# =============================================================================
# CALLBACK: custom_test_command
# Run the opentelemetry-instrumentation test suite from the cloned monorepo.
# All packages and test deps are already installed by the template + pre_test.
# =============================================================================
custom_test_command() {
    log_info "Running opentelemetry-instrumentation tests..."
    if ! python -m pytest opentelemetry-instrumentation/tests/ -x -q; then
        log_error "opentelemetry-instrumentation tests failed"
        return 1
    fi
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

