#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : impyla
# Version       : v0.21.0
# Source repo   : https://github.com/cloudera/impyla.git
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="impyla"
PACKAGE_VERSION="${1:-v0.21.0}"
PACKAGE_URL="https://github.com/cloudera/impyla"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 git krb5-devel krb5-libs krb5-workstation libffi make python3 python3-devel python3-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# =============================================================================
# Skip tests - tests require running Impala/Hive server
# =============================================================================
SKIP_TESTS="true"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
