#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pycurl
# Version       : REL_7_45_6
# Source repo   : https://github.com/pycurl/pycurl
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pycurl"
PACKAGE_VERSION="${1:-REL_7_45_6}"
PACKAGE_URL="https://github.com/pycurl/pycurl"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel libcurl libcurl-devel openssl-devel gcc make"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install build backend and test dependencies
# =============================================================================
pre_test() {
    log_info "Installing test-only dependencies (flask, flaky)"
    python -m pip install flask flaky

    log_info "Building fake-curl shared library fixtures required by setup_test.py"
    make -C tests/fake-curl/libcurl
}

# =============================================================================
# CALLBACK: custom_test_command — pytest with test deselections
# =============================================================================
# Deselected: UBI 9 ships libcurl-minimal (no SMTP/TFTP support). These options
# (MAIL_FROM/RCPT/AUTH, TFTP_BLKSIZE) return CURLE_UNKNOWN_OPTION (48) at runtime.
# The @util.min_libcurl guards (>=7.19.4/7.20.0/7.25.0) only check version, not
# compiled-in protocol support, so tests run and fail instead of being skipped.
custom_test_command() {
    log_info "Running pytest, deselecting SMTP/TFTP tests that fail on libcurl-minimal (no SMTP/TFTP protocol support)"
    python -m pytest \
        --deselect tests/option_constants_test.py::OptionConstantsTest::test_mail_auth \
        --deselect tests/option_constants_test.py::OptionConstantsTest::test_mail_from \
        --deselect tests/option_constants_test.py::OptionConstantsTest::test_mail_rcpt \
        --deselect tests/option_constants_test.py::OptionConstantsTest::test_tftp_blksize_setopt
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
