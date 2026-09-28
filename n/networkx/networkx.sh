#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : networkx
# Version       : networkx-3.6.1
# Source repo   : https://github.com/networkx/networkx
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# =============================================================================
# REQUIRED: Package metadata
# =============================================================================

PACKAGE_NAME="networkx"
PACKAGE_VERSION="${1:-networkx-3.6.1}"
PACKAGE_URL="https://github.com/networkx/networkx"

# networkx tags are prefixed with "networkx-" (e.g. networkx-3.6.1) rather
# than the standard "v" prefix. Strip the "networkx-" prefix so the template
# can install the correct version from PyPI (e.g. networkx==3.6.1).
PYPI_VERSION="${PACKAGE_VERSION#networkx-}"

NOARCH="true"

RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
