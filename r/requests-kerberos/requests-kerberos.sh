#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : requests-kerberos
# Version       : v0.14.0
# Source repo   : https://github.com/requests/requests-kerberos
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="requests-kerberos"
PACKAGE_VERSION="${1:-v0.14.0}"
PACKAGE_URL="https://github.com/requests/requests-kerberos"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git krb5-devel openssl-devel python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — pre-install gssapi before build (needs krb5-config)
# =============================================================================
pre_build() {
    log_info "Installing gssapi C extension and pyspnego[kerberos]"
    python -m pip install gssapi "pyspnego[kerberos]"
}

# =============================================================================
# CALLBACK: pre_test — re-install gssapi in isolated test venv
# =============================================================================
pre_test() {
    log_info "Installing gssapi C extension into test venv"
    python -m pip install gssapi "pyspnego[kerberos]"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

