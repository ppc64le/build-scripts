#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : <PACKAGE_NAME>           # TODO: Replace with package name
# Version       : <VERSION>                # TODO: Replace with default version
# Source repo   : <GIT_URL>                # TODO: Replace with git URL
# Tested on     : UBI:9.6
# Language      : PHP
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
PACKAGE_NAME="${PACKAGE_NAME}"              # TODO: e.g., "monolog"
PACKAGE_VERSION="${1:-PACKAGE_VERSION}"     # TODO: e.g., "3.5.0"
PACKAGE_URL="${PACKAGE_URL}"                # TODO: e.g., "https://github.com/Seldaek/monolog"

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make php php-devel php-pear php-json php-mbstring php-xml php-zip composer"
DEB_DEP_PKGS="git gcc g++ make php php-dev php-pear php-json php-mbstring php-xml php-zip composer"
SLES_DEP_PKGS="git gcc gcc-c++ make php8 php8-devel php8-pear php8-json php8-mbstring php8-xml php8-zip php-composer"

# =============================================================================
# OPTIONAL: Callback functions
# Uncomment and customize only what you need
# =============================================================================

# # Apply patches after cloning
# post_clone() {
#     git apply "${SCRIPT_DIR}/patches/fix.patch"
# }

# # Custom test command (overrides default phpunit)
# custom_test_command() {
#     ./vendor/bin/phpunit --testsuite unit
# }

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../templates/php.sh"
