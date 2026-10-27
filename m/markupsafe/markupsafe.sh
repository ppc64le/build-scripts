#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : markupsafe
# Version       : 2.1.5
# Source repo   : https://github.com/pallets/markupsafe
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Pranith Rao <Pranith.Rao@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="markupsafe"
PACKAGE_VERSION="${1:-2.1.5}"
PACKAGE_URL="https://github.com/pallets/markupsafe"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git python3 python3-devel.ppc64le"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACKS
# =============================================================================
post_clone() {
    # Fix invalid pyproject.toml license field (PORTING_RULE.md section A)
    # ONLY apply this for versions < 3 (using legacy setuptools < 70)
    local ms_major="${PACKAGE_VERSION%%.*}"
    if [[ "$ms_major" -lt 3 ]] 2>/dev/null && [[ -f "pyproject.toml" ]]; then
        log_info "Applying license table formatting patch for legacy setuptools..."
        sed -i 's/^license = "BSD-3-Clause"$/license = {text = "BSD-3-Clause"}/' "pyproject.toml"
    fi
}

install_pyproject_dependencies() {
    if [[ -f "pyproject.toml" ]]; then
        log_info "Extracting build-system requirements from pyproject.toml..."
        python -m pip install tomli
        python -m pip install setuptools wheel
        python -c "
import tomli
import subprocess
import sys
with open('pyproject.toml', 'rb') as f:
    requires = tomli.load(f).get('build-system', {}).get('requires', [])
    if requires:
        subprocess.run([sys.executable, '-m', 'pip', 'install'] + requires, check=True)
" || log_warn "Failed to install some build requirements"
    else
        log_warn "pyproject.toml not found, using fallback dependencies for older versions"
        python -m pip install setuptools wheel
    fi
}

pre_build() {
    log_info "Running pre_build hook -- installing requirements"
    install_pyproject_dependencies
}

pre_test() {
    log_info "Running pre_test hook -- installing requirements for testing"
    install_pyproject_dependencies
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
