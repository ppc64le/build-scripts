#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : <PACKAGE_NAME>           # TODO: Replace with package name
# Version       : <VERSION>                # TODO: Replace with default version
# Source repo   : <GIT_URL>                # TODO: Replace with git URL
# Tested on     : UBI:9.6
# Language      : Node
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
PACKAGE_NAME="${PACKAGE_NAME}"              # TODO: e.g., "express"
PACKAGE_VERSION="${1:-PACKAGE_VERSION}"     # TODO: e.g., "v4.18.2"
PACKAGE_URL="${PACKAGE_URL}"                # TODO: e.g., "https://github.com/expressjs/express"

# =============================================================================
# OPTIONAL: Node.js version (default: 20)
# =============================================================================
# NODE_VERSION="20"

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel gcc gcc-c++ make"
DEB_DEP_PKGS="git python3 python3-dev gcc g++ make curl"
SLES_DEP_PKGS="git python3 python3-devel gcc gcc-c++ make curl"

# =============================================================================
# OPTIONAL: Callback functions
# Uncomment and customize only what you need
# =============================================================================

# # Apply patches after cloning
# post_clone() {
#     git apply "${SCRIPT_DIR}/patches/fix.patch"
# }

# # Custom test command (overrides default npm test)
# custom_test_command() {
#     npm run test:unit
# }

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../templates/node.sh"
