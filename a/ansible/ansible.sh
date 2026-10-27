#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ansible
# Version       : v2.19.2
# Source repo   : https://github.com/ansible/ansible
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ansible"
PACKAGE_VERSION="${1:-v2.19.2}"
PACKAGE_URL="https://github.com/ansible/ansible"
PYPI_NAME="ansible-core"
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="libyaml-devel openssh-clients openssh-server"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install test dependencies and reinstall PyYAML with libyaml support
# =============================================================================
# bcrypt>=4.0 dropped __about__ attribute; passlib uses it to detect the bcrypt
# backend and falls back to a broken path causing ValueError in bcrypt tests
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install PyYAML
    python -m pip install pytest-xdist pytest-mock
    python -m pip install -r test/units/requirements.txt
    python -m pip install "bcrypt<4.0"
}

# =============================================================================
# CALLBACK: custom_test_command — use ansible-test units (upstream test runner)
#   Plain pytest against test/units/ causes Python 3.12 crashes (os.stat
#   monkey-patching, parametrize mismatches, AnsibleModule() at import time);
#   ansible-test sets required env vars and scopes to units/ automatically.
#   sanity omitted: it flags third-party pkg issues (e.g. passlib) as FATAL.
#   --exclude test/units/module_utils/basic/test_set_mode_if_different.py:
#   parametrize mismatch crashes collection; path is relative to repo root.
# =============================================================================
custom_test_command() {
    log_info "Running unit tests via ansible-test"
    ./bin/ansible-test units --python "${PYTHON_VERSION##python}" \
        --exclude test/units/module_utils/basic/test_set_mode_if_different.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

