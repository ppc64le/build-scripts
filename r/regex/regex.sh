#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : regex
# Version       : 2024.11.6
# Source repo   : https://github.com/mrabarnett/mrab-regex
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="regex"
PACKAGE_VERSION="${1:-2024.11.6}"
PACKAGE_URL="https://github.com/mrabarnett/mrab-regex"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — patch test file so pytest does not treat unittest.main() as failure
# =============================================================================
post_clone() {
    # pytest treats sys.exit() raised by unittest.main() as a SystemExit failure even when
    # all tests pass; exit=False suppresses that behaviour
    log_info "Patching regex_3/test_regex.py: setting exit=False in unittest.main()"
    sed -i 's/unittest\.main(verbosity=2)/unittest.main(verbosity=2, exit=False)/' regex_3/test_regex.py
}

# =============================================================================
# CALLBACK: pre_test — upgrade build tools to fix 'invalid command bdist_wheel'
# =============================================================================
pre_test() {
    log_info "Upgrading pip, setuptools, and wheel to resolve 'invalid command bdist_wheel' error"
    python -m pip install --upgrade pip setuptools wheel
}

# =============================================================================
# CALLBACK: custom_test_command — run test suite via unittest discover
# =============================================================================
custom_test_command() {
    # regex uses unittest.TestCase directly; use unittest discover rather than pytest
    # to avoid pytest collection overhead and plugin interference
    log_info "Running tests via unittest discover"
    python -m unittest discover
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"