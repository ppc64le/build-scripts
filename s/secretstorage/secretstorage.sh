#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : secretstorage
# Version       : 3.3.3
# Source repo   : https://github.com/mitya57/secretstorage.git
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="secretstorage"
PACKAGE_VERSION="${1:-3.3.3}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://github.com/mitya57/secretstorage"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel gcc gcc-c++ gcc-gfortran git libX11-devel libjpeg-devel make openssl-devel python-devel wget xz-devel zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH=true

custom_test_command() {
    # -----------------------------------------------------------------------------
    # secretstorage requires a running D-Bus session to execute tests.
    # In container/CI environments, DBUS_SESSION_BUS_ADDRESS is not set,
    # which leads to SecretServiceNotAvailableException.
    #
    # dbus-run-session:
    #   - Starts a temporary D-Bus session
    #   - Sets required environment variables
    #   - Cleans up automatically after execution
    #
    # Some tests require a full Secret Service backend (e.g., GNOME Keyring),
    # which is not available in minimal environments. These tests are skipped
    # to ensure stable and reproducible CI runs.
    # -----------------------------------------------------------------------------
    python -m pytest -v -k "not (CollectionTest or ItemTest or ExceptionsTest or ContextManagerTest)"
}


# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
