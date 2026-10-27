#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : uritools
# Version       : v6.0.1
# Source repo   : https://github.com/tkem/uritools
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="uritools"
PACKAGE_VERSION="${1:-v6.0.1}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://github.com/tkem/uritools"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make python3 python3-devel python3-pip sqlite-devel wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

pre_build() {
    # Check if version >= v6.0.0 (matches v6.0.0+, v6.1+, v7+, etc.)
    if [[ "$PACKAGE_VERSION" =~ ^v?([6-9]|[1-9][0-9]+)\. ]]; then
        # v6.0.0+ requires Python 3.10+
        if [[ $(echo "$LANGUAGE_VERSION" | cut -d. -f1) -eq 3 ]] && [[ $(echo "$LANGUAGE_VERSION" | cut -d. -f2) -lt 10 ]]; then
            log_error "Uritools $PACKAGE_VERSION does not support Python $LANGUAGE_VERSION. Requires Python 3.10+."
            return 1
        fi
    fi
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"