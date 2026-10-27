#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : natsort
# Version       : 8.4.0
# Source repo   : https://github.com/SethMMorton/natsort
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="natsort"
PACKAGE_VERSION="${1:-8.4.0}"
PACKAGE_URL="https://github.com/SethMMorton/natsort"

RH_DEP_PKGS=""
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH=true

pre_test() {
    log_info "Installing test dependencies"
    python -m pip install hypothesis pytest-mock pytest-xdist
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"