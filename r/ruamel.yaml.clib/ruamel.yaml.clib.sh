#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ruamel.yaml.clib
# Version       : 0.2.15
# Source repo   : https://github.com/ruamel/yaml.clib
# Tested on     : UBI 9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <ich@us.ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ruamel.yaml.clib"
PACKAGE_VERSION="${1:-0.2.15}"
PACKAGE_URL="https://github.com/ruamel/yaml.clib"

# The git repository clones into yaml.clib, not ruamel.yaml.clib
CLONE_DIR="yaml.clib"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — read setuptools requirement from pyproject.toml
# =============================================================================
post_clone() {
    log_info "Reading setuptools version requirement from pyproject.toml"
    if [[ -f "pyproject.toml" ]]; then
        setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
        if [[ -n "$setuptools_req" ]]; then
            SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
            SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
            log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
        else
            log_info "No setuptools pin found in pyproject.toml — using template default"
        fi
    else
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_test — install build deps and runtime dependency in test venv
# =============================================================================
pre_test() {
    # C extension: ensure build tools are present in .venv-test (does not inherit from .venv-build)
    python -m pip install --upgrade pip setuptools wheel
    # Runtime dependency required to resolve the ruamel namespace for _ruamel_yaml import
    python -m pip install ruamel.yaml
}

# =============================================================================
# CALLBACK: custom_test_command — build and import-verify the C extension
# =============================================================================
# The upstream tox.ini hardcodes /data1/DATA/tox/... (author's machine paths) in
# toxworkdir and commands, causing PermissionError on CI. Worse, when containers
# share a pre-populated toxworkdir across Python versions the pip bundled inside
# the tox venv becomes corrupt (mixed-version pip/_vendor errors). We skip tox
# entirely and verify the C extension by direct import instead.
custom_test_command() {
    python -c "import _ruamel_yaml; print('_ruamel_yaml C extension imported successfully')"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
