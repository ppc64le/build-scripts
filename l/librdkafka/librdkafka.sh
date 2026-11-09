#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : librdkafka
# Version       : v2.10.0
# Source repo   : https://github.com/confluentinc/librdkafka
# Tested on     : UBI:9.6
# Language      : C
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="librdkafka"
PACKAGE_VERSION="${1:-v2.10.0}"
PACKAGE_URL="https://github.com/confluentinc/librdkafka"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="librdkafka"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make openssl-devel cyrus-sasl-devel zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build Configuration
# =============================================================================
# The upstream test suite requires a live Kafka broker, so tests are skipped.
SKIP_TESTS="true"
LICENSE_FILE="LICENSE"
LICENSE_SPDX="BSD-2-Clause"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/base.sh"

