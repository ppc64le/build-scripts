#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : filelock
# Version       : 3.18.0
# Source repo   : https://github.com/tox-dev/py-filelock
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Rosman Carino <rcarino@ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="filelock"
PACKAGE_VERSION="${1:-3.18.0}"
PACKAGE_URL="https://github.com/tox-dev/py-filelock"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building filelock
# =============================================================================
RH_DEP_PKGS="git python3 python3-pip python3-devel"
DEB_DEP_PKGS="git python3 python3-pip python3-dev python3-venv"
SLES_DEP_PKGS="git python3 python3-pip python3-devel"

# =============================================================================
# OPTIONAL: Package configuration
# =============================================================================
# filelock is a pure Python package (no compiled extensions)
NOARCH="true"

# =============================================================================
# pre_test(): Adding dependencies for test suite
# =============================================================================
pre_test() {
    python -m pip install \
        pytest-asyncio \
        pytest-timeout \
        pytest-mock \
        pytest-cov \
        covdefaults \
        virtualenv
}
# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
