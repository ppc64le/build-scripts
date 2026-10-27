#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : flask-security
# Version       : 5.7.1
# Source repo   : https://github.com/pallets-eco/flask-security
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="flask-security"
PACKAGE_VERSION="${1:-5.7.1}"
PACKAGE_URL="https://github.com/pallets-eco/flask-security"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"

# =============================================================================
# CALLBACK: pre_build — enforce minimum Python version for flask-security >= 5.7.0
# =============================================================================
pre_build() {
    log_info "Checking Python version compatibility for flask-security ${PACKAGE_VERSION}"

    # Convert PACKAGE_VERSION to a tuple (array) — strip leading 'v', split on dots
    local pkg_ver=(${PACKAGE_VERSION#v})
    pkg_ver=(${pkg_ver//./ })

    # For flask-security >= 5.7.0, Python 3.10+ is required
    # Logic: (Major > 5) OR (Major == 5 AND Minor >= 7)
    if [[ ${pkg_ver[0]} -gt 5 ]] || [[ ${pkg_ver[0]} -eq 5 && ${pkg_ver[1]} -ge 7 ]]; then

        # Convert LANGUAGE_VERSION to a tuple for comparison
        local lang_ver=(${LANGUAGE_VERSION//./ })

        # Fail early if Python < 3.10 — avoids a confusing import error at test time
        if [[ ${lang_ver[0]} -eq 3 && ${lang_ver[1]} -lt 10 ]]; then
            log_error "flask-security ${PACKAGE_VERSION} does not support Python ${LANGUAGE_VERSION}. Requires Python 3.10+."
            return 1
        fi
    fi
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"