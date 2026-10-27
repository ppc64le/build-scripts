#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : treepoem
# Version       : 3.27.1
# Tested on     : UBI 9.6
# Source repo   : https://github.com/adamchainz/treepoem
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="treepoem"
PACKAGE_VERSION="${1:-3.27.1}"
PACKAGE_URL="https://github.com/adamchainz/treepoem"

# =============================================================================
# OPTIONAL: Build configuration
# =============================================================================
NOARCH="true"

BUILD_DEPS=${BUILD_DEPS:-"ghostscript:ghostpdl-10.03.1"}

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git python3 python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_test
# =============================================================================

pre_test() {
    log_info "Installing test dependencies..."
    python -m pip install --upgrade setuptools wheel tox-uv uv

    local _gs_version=""
    if [[ "${PACKAGE_VERSION}" == "3.24.0" ]]; then
        _gs_version="ghostpdl-10.0.0"
    fi

    if ! source_artifact ghostscript "${_gs_version}"; then
        log_error "ghostscript artifact not found!"
        log_error "Build ghostscript first: g/ghostscript/ghostscript.sh"
        return 1
    fi

}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
