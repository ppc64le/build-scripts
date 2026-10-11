#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ruamel-yaml-clib
# Version       : 0.2.11
# Source repo   : https://github.com/ruamel/yaml.clib
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sjtharun <sjtharun@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ruamel-yaml-clib"
PACKAGE_VERSION="${1:-0.2.11}"
PACKAGE_URL="https://github.com/ruamel/yaml.clib"

# The git repository clones into yaml.clib, not ruamel-yaml-clib
CLONE_DIR="yaml.clib"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install Cython so the C extension can be compiled
#           during `python -m build --no-isolation`
# =============================================================================
pre_build() {
    log_info "Installing Cython build dependency for ruamel.yaml.clib C extension"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "cython<3.0.0"
}

# =============================================================================
# CALLBACK: pre_test — mirror build backend deps, Cython, and ruamel.yaml runtime dep
# =============================================================================
pre_test() {
    log_info "Installing setuptools, wheel, and pip into test venv for ${PACKAGE_NAME}"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "cython<3.0.0"
    log_info "Installing ruamel.yaml runtime dependency for namespace resolution"
    python -m pip install ruamel.yaml
}

# =============================================================================
# CALLBACK: custom_test_command — import smoke-test C extension directly
# =============================================================================
custom_test_command() {
    log_info "Running import smoke test for ${PACKAGE_NAME} C extension"
    python -c "import _ruamel_yaml; print('_ruamel_yaml C extension imported successfully')"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
