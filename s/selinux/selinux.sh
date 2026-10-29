#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : selinux
# Version       : 0.3.0
# Source repo   : https://github.com/pycontribs/selinux
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="selinux"
PACKAGE_VERSION="${1:-0.3.0}"
PACKAGE_URL="https://github.com/pycontribs/selinux"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"

# =============================================================================
# CALLBACK: custom_test_command — bypass tox; run only the two checks tox actually executes
# =============================================================================
# The upstream tox.ini [testenv] lists paramiko -> bcrypt (Rust extension) and
# molecule[docker] as deps, but the actual test commands are only:
#   python -c "import selinux"
#   python -m pip check
# The pytest line is commented out upstream. Running tox would fail trying to
# build bcrypt (requires Rust) because no default Rust toolchain is configured.
# We skip tox and run the two real checks directly.
custom_test_command() {
    log_info "Verifying selinux import"
    python -c "import selinux"

    log_info "Checking for dependency conflicts"
    python -m pip check
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

