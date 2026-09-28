#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : <PACKAGE_NAME>           # TODO: Replace with package name
# Version       : <VERSION>                # TODO: Replace with default version
# Source repo   : <GIT_URL>                # TODO: Replace with git URL
# Tested on     : UBI:9.6
# Language      : Ruby
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
PACKAGE_NAME="${PACKAGE_NAME}"              # TODO: e.g., "rails"
PACKAGE_VERSION="${1:-PACKAGE_VERSION}"     # TODO: e.g., "v7.1.2"
PACKAGE_URL="${PACKAGE_URL}"                    # TODO: e.g., "https://github.com/rails/rails"

# =============================================================================
# OPTIONAL: Ruby version (default: 3.2.0, uses system Ruby if available)
# =============================================================================
# RUBY_VERSION="3.2.0"

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make ruby ruby-devel rubygem-rake libffi-devel openssl-devel readline-devel zlib-devel libyaml-devel"
DEB_DEP_PKGS="git gcc g++ make ruby ruby-dev rake libffi-dev libssl-dev libreadline-dev zlib1g-dev libyaml-dev"
SLES_DEP_PKGS="git gcc gcc-c++ make ruby ruby-devel rubygem-rake libffi-devel libopenssl-devel readline-devel zlib-devel"

# =============================================================================
# OPTIONAL: Callback functions
# Uncomment and customize only what you need
# =============================================================================

# # Apply patches after cloning
# post_clone() {
#     git apply "${SCRIPT_DIR}/patches/fix.patch"
# }

# # Custom test command (overrides default rspec/rake)
# custom_test_command() {
#     bundle exec rspec spec/unit/
# }

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../templates/ruby.sh"
