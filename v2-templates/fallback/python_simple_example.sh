#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : python-fire
# Version       : v0.7.0
# Source repo   : https://github.com/google/python-fire
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Your Name <your.email@example.com>
#
# This is a SIMPLE example - no callbacks needed.
# Just define the required variables and source the template.
# -----------------------------------------------------------------------------

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="${PACKAGE_NAME}"
PACKAGE_VERSION="${1:-PACKAGE_VERSION}"
PACKAGE_URL="${PACKAGE_URL}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc"
SLES_DEP_PKGS="git python3 python3-devel python3-pip gcc"

# =============================================================================
# Execute the build (sources the template which runs the workflow)
# =============================================================================
source "${SCRIPT_DIR}/../python.sh"
