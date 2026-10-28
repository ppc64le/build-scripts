#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ollama
# Version       : v0.12.10
# Source repo   : https://github.com/ollama/ollama
# Tested on     : 9.6
# Language      : Go
# Script License: Apache License, Version 2 or later
# Maintainer    : Shalini Salomi Bodapati <Shalini-Salomi-Bodapati@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: ollama_v0.12.10_ubi_9.6.sh
#   - Callbacks generated: post_clone 
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ollama"
PACKAGE_VERSION="${1:-v0.12.10}"
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
    wget -q -O build_power.patch https://github.com/ollama/ollama/commit/67b8d3c817fbdc57fedad9b032d0efc10285220a.patch
    wget -q -O set_threads_env.patch https://github.com/ollama/ollama/commit/1364a887a1d7c25522e9c921d55e50a6aea44964.patch
    wget -q -O enable_mma.patch https://github.com/ollama/ollama/commit/fe924304809ae8e6bd6957b0ce5759eb2a796d42.patch
    patch -p1 < build_power.patch
    patch -p1 < set_threads_env.patch
    patch -p1 < enable_mma.patch
}

# =============================================================================
# Execute the build (invokes the Go template)
# =============================================================================
source "${SCRIPT_DIR}/../v2-templates/go.sh"
