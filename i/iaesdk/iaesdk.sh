#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : iaesdk
# Version       : v3.3.0
# Source repo   : https://github.com/IBM/ibm-iae-python-sdk
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Vinod.K1 <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="iaesdk"
PACKAGE_VERSION="${1:-v3.3.0}"
PACKAGE_URL="https://github.com/IBM/ibm-iae-python-sdk"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"


# =============================================================================
# CALLBACK: custom_install — Install iaesdk sdist with --no-build-isolation
# =============================================================================
custom_install() {
    # iaesdk is a pure-Python (noarch) package distributed on PyPI as an sdist
    # only (no pre-built wheel). Its setup.py imports pkg_resources, which was
    # removed in setuptools>=82.
    #
    # pip's default build-isolation creates a temporary env under /tmp/pip-build-env-*/
    # and downloads the latest setuptools into it, ignoring whatever version is
    # pinned in the current venv. This causes:
    #   ModuleNotFoundError: No module named 'pkg_resources'
    #
    # Fix: Pass --no-build-isolation so pip skips the isolated temp env entirely
    # and uses the venv's setuptools directly when building the sdist.
    log_info "Installing iaesdk==${PACKAGE_VERSION#v}"
    python -m pip install --no-build-isolation "iaesdk==${PACKAGE_VERSION#v}"
}

# =============================================================================
# CALLBACK: pre_test — Install test dependencies before running tests
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install responses
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
