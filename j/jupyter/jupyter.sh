#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : jupyter
# Version       : v1.1.1
# Source repo   : https://github.com/jupyter/jupyter
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="jupyter"
PACKAGE_VERSION="${1:-v1.1.1}"
PACKAGE_URL="https://github.com/jupyter/jupyter"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# NOARCH - install from PyPI
# =============================================================================
NOARCH="true"

# =============================================================================
# CALLBACK: custom_test_command
# Basic import test to verify the package installed correctly
# =============================================================================
custom_test_command() {
    log_info "Running basic import test for jupyter..."
    python -c "import jupyter; from importlib.metadata import version; print('jupyter version:', version('jupyter')); print('jupyter import successful.')"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
