#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : requests-oauthlib
# Version       : v2.0.0
# Source repo   : https://github.com/requests/requests-oauthlib
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="requests-oauthlib"
PACKAGE_VERSION="${1:-v2.0.0}"
PACKAGE_URL="https://github.com/requests/requests-oauthlib"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"

# =============================================================================
# CALLBACK: custom_test_command — deselect tests that require live network access
# =============================================================================
custom_test_command() {
    log_info "Running tests (deselecting tests that require outbound network access to httpbin.org / auth0.com)"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        --deselect tests/test_core.py::OAuth1Test::testCanPostBinaryData \
        --deselect tests/test_core.py::OAuth1Test::test_content_type_override \
        --deselect tests/test_core.py::OAuth1Test::test_url_is_native_str \
        --deselect tests/examples/test_native_spa_pkce_auth0.py::TestNativeAuth0Test::test_login
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

