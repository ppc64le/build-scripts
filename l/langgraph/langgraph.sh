#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : langgraph
# Version       : 0.4.8
# Source repo   : https://github.com/langchain-ai/langgraph
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="langgraph"
PACKAGE_VERSION="${1:-0.4.8}"
PACKAGE_URL="https://github.com/langchain-ai/langgraph"

# Pure Python package — all wheels are py3-none-any on PyPI
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command — import smoke test
# The upstream monorepo (langchain-ai/langgraph) contains multiple sub-libraries
# (checkpoint, checkpoint-sqlite, checkpoint-postgres, cli, sdk-py, prebuilt, etc.)
# each with their own extras and external service dependencies (redis, psycopg,
# click, langgraph_cli). Running the full test suite from the repo root fails with
# 32 collection errors due to missing sub-library installs. A smoke test confirms
# the PyPI-installed package is importable and reports its version on ppc64le.
# =============================================================================
custom_test_command() {
    log_info "Running import smoke test for langgraph"
    python -c "import langgraph; from importlib.metadata import version; print('langgraph', version('langgraph'))"
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

