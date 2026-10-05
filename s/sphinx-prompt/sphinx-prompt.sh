#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sphinx-prompt
# Version       : 1.9.0
# Source repo   : https://github.com/sbrunner/sphinx-prompt
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="sphinx-prompt"
PACKAGE_VERSION="${1:-1.9.0}"
PACKAGE_URL="https://github.com/sbrunner/sphinx-prompt"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================

RH_DEP_PKGS="git python3 python3-devel"
DEB_DEP_PKGS="git python3 python3-dev python3-venv"
SLES_DEP_PKGS=""

post_clone() {
    # Upstream 1.9.0 declares "sphinx-prompt" in the Poetry packages list, but
    # the import package is "sphinx_prompt"; keep only the valid package path.
    sed -i '/^packages = \[/,/\]/d' pyproject.toml
    sed -i '/^\[tool.poetry\]/a packages = [\n    { include = "sphinx_prompt" }\n]' pyproject.toml
}

# =============================================================================
# CALLBACK: pre_build
# Install build backend requirements before invoking the template build.
# =============================================================================
pre_build() {
    log_info "Installing Poetry build dependencies"
    python -m pip install -r requirements.txt
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
