#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tree-sitter-python
# Version       : v0.25.0
# Source repo   : https://github.com/tree-sitter/tree-sitter-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tree-sitter-python"
PACKAGE_VERSION="${1:-v0.25.0}"
PACKAGE_URL="https://github.com/tree-sitter/tree-sitter-python"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel gcc gcc-c++ make"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# tree-sitter-python v0.25.x compiles to language ABI version 15.
# tree-sitter 0.24.x only accepts ABI 13–14 → ValueError: Incompatible Language version 15.
# tree-sitter 0.25.x accepts ABI 14–15 and shares the same C ABI as tree-sitter-python 0.25.x.
# Pinned to ==0.25.0 to avoid pulling 0.26+ which has a different ABI.
TREE_SITTER_CORE_VERSION="0.25.0"

# =============================================================================
# CALLBACK: pre_build — install tree-sitter core into build venv before compilation
# =============================================================================
pre_build() {
    log_info "Installing tree-sitter==${TREE_SITTER_CORE_VERSION} into build venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "tree-sitter==${TREE_SITTER_CORE_VERSION}"
}

# =============================================================================
# CALLBACK: custom_test_command — recompile from source to fix broken .so,
# then run binding tests.
#
# Root cause: the template runs `python -m build --no-isolation` from the repo
# root, then installs the resulting wheel into .venv-test. That wheel's
# _binding.abi3.so is missing tree_sitter_python_external_scanner_create because
# scanner.c was not linked in during the wheel build. The symbol is only present
# when the extension is compiled directly inside the active venv via
# `pip install --no-build-isolation .`.
#
# Steps:
#   1. Pin tree-sitter to the ABI-compatible version first.
#   2. Uninstall the broken pre-built wheel the template already installed.
#   3. Recompile and reinstall from source — this links scanner.c correctly.
#   4. Run pytest against bindings/python/tests/.
# =============================================================================
custom_test_command() {
    log_info "Installing tree-sitter==${TREE_SITTER_CORE_VERSION} (ABI-compatible pin)"
    python -m pip install "tree-sitter==${TREE_SITTER_CORE_VERSION}"

    log_info "Removing broken pre-built wheel from test venv"
    python -m pip uninstall -y tree-sitter-python

    log_info "Recompiling and installing tree-sitter-python from source (links scanner.c)"
    python -m pip install --no-build-isolation .

    log_info "Running pytest on Python binding tests"
    python -m pytest bindings/python/tests/ \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
