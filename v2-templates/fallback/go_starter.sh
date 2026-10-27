#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : <PACKAGE_NAME>           # TODO: Replace with package name
# Version       : <VERSION>                # TODO: Replace with default version
# Source repo   : <GIT_URL>                # TODO: Replace with git URL
# Tested on     : UBI:9.6
# Language      : Go
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
PACKAGE_NAME="${PACKAGE_NAME}"              # TODO: e.g., "cobra"
PACKAGE_VERSION="${1:-PACKAGE_VERSION}"    # TODO: e.g., "v1.8.0"
PACKAGE_URL="${PACKAGE_URL}"               # TODO: e.g., "https://github.com/spf13/cobra"

# =============================================================================
# OPTIONAL: Go version (default: 1.23.4)
# =============================================================================
# GO_VERSION="1.23.4"

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make wget"
DEB_DEP_PKGS="git gcc g++ make wget"
SLES_DEP_PKGS="git gcc gcc-c++ make wget"

# =============================================================================
# OPTIONAL: Callback functions
# Uncomment and customize only what you need
# =============================================================================

# # Apply patches after cloning
# post_clone() {
#     git apply "${SCRIPT_DIR}/patches/fix.patch"
# }

# # Custom test command (overrides default go test ./...)
# custom_test_command() {
#     go test -v -race ./...
# }

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../templates/go.sh"
