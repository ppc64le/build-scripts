#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : aiosignal
# Version       : v1.2.0
# Source repo   : https://github.com/aio-libs/aiosignal.git
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Robin Jain <robin.jain1@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: aiosignal_ubi_9.3.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="aiosignal"
PACKAGE_VERSION="${1:-v1.2.0}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://github.com/aio-libs/aiosignal"
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="autoconf automake bzip2 bzip2-devel cargo cmake fontconfig-devel.ppc64le fontconfig.ppc64le gcc gcc-c++ git gzip info.ppc64le libffi-devel libtool make openblas-devel openssl-devel pkgconf-pkg-config.ppc64le python-devel sqlite-devel tar unzip wget xz yum-utils zip zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test
# Setup test environment and install additional requirements before execution
# =============================================================================
pre_test() {
    log_info "Installing specific dependencies for aiosignal tests..."
    pip install pytest-asyncio
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
