#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : psycopg2
# Version       : 2.9.10
# Source repo   : https://github.com/psycopg/psycopg2
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="psycopg2"
PACKAGE_VERSION="${1:-2.9.10}"
PACKAGE_URL="https://github.com/psycopg/psycopg2"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building psycopg2
# Note: psycopg2 requires PostgreSQL client libraries and headers
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make postgresql postgresql-devel python3-devel python3-pip openssl-devel libffi-devel zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command
# Tests are skipped - they require a running PostgreSQL database server
# which is not available in the build container environment.
# The legacy script also skipped tests due to ~700 failures on both x86 and Power.
# =============================================================================
custom_test_command() {
    log_info "Running import test for psycopg2"
    python -c "import psycopg2; print('psycopg2 version:', psycopg2.__version__)"
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
