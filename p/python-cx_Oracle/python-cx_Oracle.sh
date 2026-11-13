#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : python-cx_Oracle
# Version       : 8.3.0
# Source repo   : https://github.com/oracle/python-cx_Oracle
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="python-cx_Oracle"
PACKAGE_VERSION="${1:-8.3.0}"
PACKAGE_URL="https://github.com/oracle/python-cx_Oracle"
PYPI_NAME="cx-Oracle"


# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# setup.py imports pkg_resources, which was removed in setuptools>=82
# (pyproject.toml only declares "setuptools >= 40.6.0", so it gives no upper bound)
SETUPTOOLS_VERSION="<82"


# =============================================================================
# CALLBACK: custom_test_command — Run import-based smoke test (full test suite requires Oracle DB connection)
# =============================================================================
custom_test_command() {
    log_info "Running import smoke test (full test suite requires Oracle DB connection)"

    python -c "import cx_Oracle; print('cx_Oracle version:', cx_Oracle.version)"
    python -c "import cx_Oracle; print('cx_Oracle location:', cx_Oracle.__file__)"

    log_info "Import smoke test passed successfully"
}


# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
