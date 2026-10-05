#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : <PACKAGE_NAME>           # TODO: Replace with package name
# Version       : <VERSION>                # TODO: Replace with default version
# Source repo   : <GIT_URL>                # TODO: Replace with git URL
# Tested on     : UBI:9.6
# Language      : R
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
PACKAGE_NAME="${PACKAGE_NAME}"              # TODO: e.g., "ggplot2"
PACKAGE_VERSION="${1:-PACKAGE_VERSION}"     # TODO: e.g., "v3.4.4"
PACKAGE_URL="${PACKAGE_URL}"                    # TODO: e.g., "https://github.com/tidyverse/ggplot2"

# =============================================================================
# OPTIONAL: R configuration
# =============================================================================
# SKIP_VIGNETTES="true"                    # Skip vignette building (default: true)
# CRAN_DEPS="true"                         # Install CRAN dependencies (default: true)

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ gcc-gfortran make wget R-core R-core-devel libcurl-devel openssl-devel libxml2-devel"
DEB_DEP_PKGS="git gcc g++ gfortran make wget r-base r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev"
SLES_DEP_PKGS="git gcc gcc-c++ gcc-fortran make wget R-core R-core-devel libcurl-devel libopenssl-devel libxml2-devel"

# =============================================================================
# OPTIONAL: Callback functions
# Uncomment and customize only what you need
# =============================================================================

# # Apply patches after cloning
# post_clone() {
#     git apply "${SCRIPT_DIR}/patches/fix.patch"
# }

# # Custom test command (overrides default R CMD check)
# custom_test_command() {
#     R CMD check . --as-cran
# }

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../templates/r.sh"
