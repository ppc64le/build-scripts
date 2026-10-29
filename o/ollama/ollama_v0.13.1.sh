#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ollama
# Version       : v0.13.1
# Source repo   : https://github.com/ollama/ollama
# Tested on     : 9.6
# Language      : Go
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: ollama_v0.13.1_ubi_9.6.sh
#   - Callbacks generated: post_clone 
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ollama"
PACKAGE_VERSION="${1:-v0.13.1}"
PACKAGE_URL="https://github.com/ollama/ollama"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="binutils cmake gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make patch python python-devel python-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export CGO_LDFLAGS="-L$(pwd)/build/lib/ollama/ -lggml-cpu-power10"

# =============================================================================
# OPTIONAL: Callback functions for custom logic
# =============================================================================

# Apply patches after cloning (extracted from original script)
post_clone() {
    # TODO: Review and update patch commands from original script
    # Clone and patch Ollama
    patch -p1 < ${SCRIPT_PATH}/build_power_${PACKAGE_VERSION}.patch
    patch -p1 < ${SCRIPT_PATH}/set_threads_env_${PACKAGE_VERSION}.patch
    patch -p1 < ${SCRIPT_PATH}/enable_mma_${PACKAGE_VERSION}.patch
}

# =============================================================================
# Execute the build (invokes the Go template)
# =============================================================================
source "${SCRIPT_DIR}/../v2-templates/go.sh"
