#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : rdflib
# Version       : 7.1.4
# Source repo   : https://github.com/RDFLib/rdflib
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod.K1 <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="rdflib"
PACKAGE_VERSION="${1:-7.1.4}"
PACKAGE_URL="https://github.com/RDFLib/rdflib"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 git make openssl-devel python3 python3-devel python3-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Configuration
# =============================================================================
NOARCH="true"

custom_test_command() {
  log_info "Skipping SPARQL, service, parser, and HTTP format tests — these require network access or external resources unavailable in the build environment."
  python -m pytest --ignore=rdflib/ --ignore=test/test_extras/test_infixowl/ -k "not sparql and not service and not test_parser and not test_guess_format_for_parse_http_text_plain" "$@"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
