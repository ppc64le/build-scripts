#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : furo
# Version       : 2024.08.06
# Source repo   : https://github.com/pradyunsg/furo
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="furo"
PACKAGE_VERSION="${1:-2024.08.06}"
PACKAGE_URL="https://github.com/pradyunsg/furo"

# Pure Python package — install directly from PyPI, no compilation needed
NOARCH="true"

# Require the pre-built tree binary artifact
BUILD_DEPS=${BUILD_DEPS:-"tree-command"}

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_clone — initialize nvm from /opt/nvm so Node is available
# =============================================================================
pre_clone() {
    if [[ -d "/opt/nvm" ]]; then
        log_info "Found nvm in /opt/nvm, setting NVM_DIR"
        export NVM_DIR="/opt/nvm"
        # shellcheck source=/dev/null
        [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    fi
}

# =============================================================================
# CALLBACK: pre_test — source tree-command artifact, install test deps, cap sphinx
# =============================================================================
pre_test() {
    if ! source_artifact tree-command "upstream/2.0.2"; then
        log_error "tree-command artifact not found!"
        log_error "Build tree-command first: t/tree-command/tree-command.sh"
        return 1
    fi

    log_info "Installing test dependencies"
    python -m pip install tomli httpx

    local py_minor
    py_minor=$(python -c "import sys; print(sys.version_info.minor)")
    if [[ "$py_minor" -lt 11 ]]; then
        log_info "Python 3.${py_minor}: capping sphinx to <8.2 in pyproject.toml (sphinx>=8.2 requires Python>=3.11)"
        sed -i 's/"sphinx >= 6\.0,<9\.0"/"sphinx >= 6.0,<8.2"/' pyproject.toml
    fi
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"