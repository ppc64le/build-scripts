#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sparkmagic
# Version       : 0.20.0
# Source repo   : https://github.com/jupyter-incubator/sparkmagic
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sparkmagic"
PACKAGE_VERSION="${1:-0.20.0}"
PACKAGE_URL="https://github.com/jupyter-incubator/sparkmagic"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel cmake gcc gcc-c++ git krb5-devel libffi-devel make openblas-devel openssl-devel python3-devel sqlite-devel wget xz"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# sparkmagic is a pure-Python package — skip local build and install from PyPI.
# This avoids the auditwheel failure on py3-none-any wheels (no native code).
NOARCH="true"

# =============================================================================
# CALLBACK: post_clone — for v0.20.0 only, cd into the sparkmagic/sparkmagic/
# subdirectory where setup.py lives. The repo root has no pyproject.toml or
# setup.py at this version, so the build must run from the nested subdir.
# Newer versions are expected to have a standard layout at the repo root.
# =============================================================================
post_clone() {
    if [[ "${PACKAGE_VERSION}" == "0.20.0" ]]; then
        log_info "v0.20.0: changing into sparkmagic/ subdirectory (setup.py is nested)"
        cd sparkmagic/
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — install notebook<7 (notebook.utils was
# removed in v7+) and run tests, ignoring those that require a live
# Spark/Livy server which is not available in CI.
# =============================================================================
custom_test_command() {
    log_info "Installing notebook<7 (notebook.utils was removed in notebook v7+)"
    python -m pip install "notebook<7"

    # The following tests all require a live Spark/Livy server — not available in CI
    log_info "Running sparkmagic tests (excluding tests requiring a live Spark/Livy server)"
    python -m pytest sparkmagic/tests \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --ignore=sparkmagic/tests/test_reliablehttpclient.py \
        --ignore=sparkmagic/tests/test_kernel_magics.py \
        --ignore=sparkmagic/tests/test_configuration.py \
        --ignore=sparkmagic/tests/test_sparkmagicsbase.py \
        --ignore=sparkmagic/tests/test_sparkstorecommand.py \
        --ignore=sparkmagic/tests/test_sparkevents.py \
        --ignore=sparkmagic/tests/test_sparkkernelbase.py \
        --ignore=sparkmagic/tests/test_sparkcontroller.py \
        --ignore=sparkmagic/tests/test_remotesparkmagics.py \
        --ignore=sparkmagic/tests/test_exceptions.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

