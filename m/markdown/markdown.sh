#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : markdown
# Version       : 3.10.2
# Source repo   : https://github.com/Python-Markdown/markdown
# Tested on     : UBI: 9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="markdown"
PACKAGE_VERSION="${1:-3.10.2}"
PACKAGE_URL="https://github.com/Python-Markdown/markdown"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel gcc-toolset-13 git libffi-devel openssl-devel python3 python3-devel python3-pip wget zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

pre_build() {
    # 1. Convert PACKAGE_VERSION to a tuple (array)
    # Strip leading 'v', change dots to spaces to create an array
    local pkg_ver=(${PACKAGE_VERSION//v/})
    pkg_ver=(${pkg_ver//./ })

    # 2. Check if Package Version >= 3.10.0
    # Logic: (Major > 3) OR (Major == 3 AND Minor >= 10)
    if [[ ${pkg_ver[0]} -gt 3 ]] || [[ ${pkg_ver[0]} -eq 3 && ${pkg_ver[1]} -ge 10 ]]; then
        
        # 3. Convert LANGUAGE_VERSION to a tuple
        local lang_ver=(${LANGUAGE_VERSION//./ })
        
        # 4. Check if Python < 3.10
        # Logic: (Major == 3 AND Minor < 10)
        if [[ ${lang_ver[0]} -eq 3 && ${lang_ver[1]} -lt 10 ]]; then
            log_error "markdown $PACKAGE_VERSION does not support Python $LANGUAGE_VERSION. Requires Python 3.10+."
            return 1
        fi
    fi
}

pre_test() {
    log_info "installing test dependencies"
    python -m pip install pyyaml
}

custom_test_command() {
    # Ignore test_md_in_html.py: contains a TestSuite class with __init__ which
    # pytest cannot collect (PytestCollectionWarning treated as error).
    python -m pytest --ignore=tests/test_syntax/extensions/test_md_in_html.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
