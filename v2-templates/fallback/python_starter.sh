#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : <PACKAGE_NAME>           # TODO: Replace with package name
# Version       : <VERSION>                # TODO: Replace with default version
# Source repo   : <GIT_URL>                # TODO: Replace with git URL
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : <YOUR_NAME> <YOUR_EMAIL> # TODO: Replace with your info
# -----------------------------------------------------------------------------
# HOW TO USE THIS TEMPLATE:
#   1. Copy this file to your package directory
#   2. Replace all <PLACEHOLDERS> with actual values
#   3. Adjust dependencies for your package
#   4. Uncomment and customize callback functions if needed
#   5. Test: ./your_script.sh v1.0.0
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata (MUST be set)
# =============================================================================
PACKAGE_NAME="${PACKAGE_NAME}"               # Set by CI or override here
PACKAGE_VERSION="${1:-${PACKAGE_VERSION}}"   # Set by CI or override here
PACKAGE_URL="${PACKAGE_URL}"                 # Set by CI or override here

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
# Add packages your build needs. Common Python packages:
#   git python3 python3-devel python3-pip gcc gcc-c++ make
#   For native extensions: openssl-devel libffi-devel zlib-devel

RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc"
SLES_DEP_PKGS="git python3 python3-devel python3-pip gcc"

# =============================================================================
# OPTIONAL: Callback functions
# Uncomment and customize only what you need
# =============================================================================

# # Apply patches after cloning
# post_clone() {
#     git apply "${SCRIPT_DIR}/patches/fix.patch"
# }

# # Set environment before building
# pre_build() {
#     export SPECIAL_FLAG=1
# }

# # Custom test command (overrides default pytest/tox/nox)
# custom_test_command() {
#     python -m pytest tests/ -x
# }

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../python.sh"
