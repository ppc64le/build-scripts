#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : kafka-python
# Version       : 2.2.10
# Source repo   : https://github.com/dpkp/kafka-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="kafka-python"
PACKAGE_VERSION="${1:-2.2.10}"
PACKAGE_URL="https://github.com/dpkp/kafka-python"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git libzstd-devel python3-devel python3-pip snappy-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install dev/test dependencies from requirements-dev.txt
# =============================================================================
pre_test() {
    if [[ -f "requirements-dev.txt" ]]; then
        log_info "Installing dev/test requirements..."
        python -m pip install -r requirements-dev.txt
    fi
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

