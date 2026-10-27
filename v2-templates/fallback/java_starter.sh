#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : <PACKAGE_NAME>           # TODO: Replace with package name
# Version       : <VERSION>                # TODO: Replace with default version
# Source repo   : <GIT_URL>                # TODO: Replace with git URL
# Tested on     : UBI:9.6
# Language      : Java
# Script License: Apache License, Version 2 or later
# Maintainer    : <YOUR_NAME> <YOUR_EMAIL> # TODO: Replace with your info
# -----------------------------------------------------------------------------
# HOW TO USE THIS TEMPLATE:
#   1. Copy this file to your package directory
#   2. Replace all <PLACEHOLDERS> with actual values
#   3. Adjust dependencies for your package
#   4. Uncomment and customize callback functions if needed
#   5. Test: ./your_script.sh v1.0.0
#
# BUILD TOOLS: Supports Maven (pom.xml), Gradle (build.gradle), Ant (build.xml)
# JDK VERSIONS: Auto-tries JDK 11, 17, 21 - set JAVA_VERSION to force one
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata (MUST be set)
# =============================================================================
PACKAGE_NAME="${PACKAGE_NAME}"            # TODO: e.g., "commons-lang3"
PACKAGE_VERSION="${1:-PACKAGE_VERSION}"   # TODO: e.g., "rel/commons-lang-3.14.0"
PACKAGE_URL="${PACKAGE_URL}"                  # TODO: e.g., "https://github.com/apache/commons-lang"

# =============================================================================
# OPTIONAL: Java/Build configuration
# =============================================================================
# JAVA_VERSION="17"                        # Force specific JDK (11, 17, or 21)
# BUILD_TOOL="maven"                       # Force build tool (maven, gradle, ant)

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make wget tar java-11-openjdk java-11-openjdk-devel java-17-openjdk java-17-openjdk-devel java-21-openjdk java-21-openjdk-devel ant"
DEB_DEP_PKGS="git gcc g++ make wget tar openjdk-11-jdk openjdk-17-jdk openjdk-21-jdk ant"
SLES_DEP_PKGS="git gcc gcc-c++ make wget tar java-11-openjdk java-11-openjdk-devel java-17-openjdk java-17-openjdk-devel java-21-openjdk java-21-openjdk-devel ant"

# =============================================================================
# OPTIONAL: Callback functions
# Uncomment and customize only what you need
# =============================================================================

# # Apply patches after cloning
# post_clone() {
#     git apply "${SCRIPT_DIR}/patches/fix.patch"
# }

# # Set specific Java version before build
# pre_build() {
#     export JAVA_TOOL_OPTIONS="-Xmx4g"
# }

# # Custom test command
# custom_test_command() {
#     mvn test -Dtest=SpecificTest
# }

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../templates/java.sh"
