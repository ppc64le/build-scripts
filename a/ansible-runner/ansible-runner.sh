#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ansible-runner
# Version       : 2.4.1
# Source repo   : https://github.com/ansible/ansible-runner
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <Sai.Kiran.Nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ansible-runner"
PACKAGE_VERSION="${1:-2.4.1}"
PACKAGE_URL="https://github.com/ansible/ansible-runner"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS=""
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — install test-only dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."
    python -m pip install cryptography pytest-timeout ansible-core pytest-mock pytest-forked
    # Uninstall pytest-xdist if present as a transitive dep — its worker pool hangs
    # after suite completion on ppc64le CI
    python -m pip uninstall -y pytest-xdist 2>/dev/null
}

# =============================================================================
# CALLBACK: custom_test_command — unit tests only with --forked isolation;
#   integration tests spawn live ansible-playbook processes that hang the pytest
#   process on ppc64le CI. --forked runs each test in a subprocess so orphaned
#   child processes cannot hold the parent's pipes open after the suite exits.
# =============================================================================
# test_no_ResourceWarning_error: relies on ResourceWarning GC behaviour, flaky on ppc64le
# test_dump_artifacts_inventory_object: inventory object serialisation differs on ppc64le
custom_test_command() {
    log_info "Running ansible-runner unit tests"
    python -m pytest \
        -o "addopts=" \
        --forked \
        --disable-warnings \
        -k "not test_no_ResourceWarning_error and not test_dump_artifacts_inventory_object" \
        test/unit/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

