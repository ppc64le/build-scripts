#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : certifi
# Version       : 2026.05.20
# Source repo   : https://github.com/certifi/python-certifi
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="certifi"
PACKAGE_URL="https://github.com/certifi/python-certifi"
NOARCH="true"

# GitHub tags are zero-padded (2026.05.20) while PyPI versions are not (2026.5.20).
# Accept either form as $1 and derive both.
CERTIFI_VER="${1:-2026.05.20}"
CERTIFI_VER="${CERTIFI_VER#v}"
cert_ver=(${CERTIFI_VER//./ })
PACKAGE_VERSION="$(printf '%d.%02d.%02d' "$((10#${cert_ver[0]}))" "$((10#${cert_ver[1]}))" "$((10#${cert_ver[2]}))")"
PYPI_VERSION="$(printf '%d.%d.%d' "$((10#${cert_ver[0]}))" "$((10#${cert_ver[1]}))" "$((10#${cert_ver[2]}))")"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ gcc-gfortran git make openssl-devel python3-devel wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"