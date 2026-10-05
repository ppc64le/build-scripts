#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : platformdirs
# Version       : 4.3.6
# Source repo   : https://github.com/tox-dev/platformdirs
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : rcarino <rcarino@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="platformdirs"
PACKAGE_VERSION="${1:-4.3.6}"
PACKAGE_URL="https://github.com/tox-dev/platformdirs"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-pip python3-devel"
DEB_DEP_PKGS="git python3 python3-pip python3-dev"
SLES_DEP_PKGS="git python3 python3-pip python3-devel"

# =============================================================================
# OPTIONAL: Custom environment variables
# =============================================================================
# This is a NoArch (pure Python) wheel
NOARCH="true"

# =============================================================================
# pre_test: Adding dependencies for test suite
# =============================================================================
pre_test () {
	python -m pip install appdirs pytest-mock
}

# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
