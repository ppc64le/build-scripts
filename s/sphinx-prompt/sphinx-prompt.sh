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

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sphinx-prompt"
PACKAGE_VERSION="${1:-1.9.0}"
PACKAGE_URL="https://github.com/sbrunner/sphinx-prompt"
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel"
DEB_DEP_PKGS="git python3 python3-dev python3-venv"
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — fix package path and pin version for wheel build
# =============================================================================
post_clone() {
    log_info "Patching pyproject.toml: fixing package path and pinning version"

    # Upstream 1.9.0 declares "sphinx-prompt" in the Poetry packages list, but
    # the import package is "sphinx_prompt"; keep only the valid package path.
    sed -i '/^packages = \[/,/\]/d' pyproject.toml
    sed -i '/^\[tool.poetry\]/a packages = [\n    { include = "sphinx_prompt" }\n]' pyproject.toml

    # poetry-dynamic-versioning reads the version from git tags at build time.
    # In CI the HEAD may not sit exactly on the tag (distance > 0), causing it
    # to fall back to "0.0.0" and fail wheel version validation.
    # Fix: hard-pin the version in pyproject.toml and disable dynamic versioning
    # so python -m build always produces the expected version.
    sed -i "s/^version = \"0.0.0\"/version = \"${PACKAGE_VERSION}\"/" pyproject.toml
    sed -i 's/^enable = true/enable = false/' pyproject.toml
}

# =============================================================================
# CALLBACK: pre_test — install Poetry build dependencies into test venv
# =============================================================================
pre_test() {
    log_info "Installing Poetry build dependencies"
    python -m pip install -r requirements.txt
}

# =============================================================================
# CALLBACK: custom_test_command — deselect test broken by Pygments version change
# =============================================================================
custom_test_command() {
    log_info "Running pytest (deselecting test broken by Pygments HTML-escaping change)"
    # arguments10 expects &quot;tree&quot; (old Pygments HTML-escaped output) but newer
    # Pygments renders literal "tree" — this is an upstream test compatibility issue,
    # not a regression in sphinx-prompt itself.
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        -k "not arguments10"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"