#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : hdijupyterutils
# Version       : 0.20.0
# Source repo   : https://github.com/jupyter-incubator/sparkmagic
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <Sai.Kiran.Nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="hdijupyterutils"
PACKAGE_VERSION="${1:-0.20.0}"
PACKAGE_URL="https://github.com/jupyter-incubator/sparkmagic"

NOARCH="true"
# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel krb5-devel libffi-devel make openssl-devel python3-devel zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — cd into the hdijupyterutils/ subdirectory.
# The sparkmagic monorepo is cloned; hdijupyterutils lives in its own subdir.
# The build and test phases must run from that subdirectory.
# =============================================================================
post_clone() {
    log_info "Changing into hdijupyterutils/ subdirectory (package lives in sparkmagic monorepo)"
    cd hdijupyterutils/
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies not provided by the template.
# mock is required by the hdijupyterutils test suite.
# =============================================================================
pre_test() {
    log_info "Installing test dependencies: mock"
    python -m pip install mock
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest excluding test_send_to_handler
# which requires a live HDInsight/Livy endpoint not available in CI.
# =============================================================================
custom_test_command() {
    log_info "Running hdijupyterutils tests (excluding test_send_to_handler)"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        -k "not test_send_to_handler"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

