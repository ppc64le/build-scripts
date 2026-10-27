#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : python-memcached
# Version       : 1.62
# Source repo   : https://github.com/linsomniac/python-memcached
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="python-memcached"
PACKAGE_VERSION="${1:-1.62}"
PACKAGE_URL="https://github.com/linsomniac/python-memcached"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git memcached"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — patch __version__ in memcache.py to match PACKAGE_VERSION
# =============================================================================
post_clone() {
    log_info "Patching __version__ in memcache.py to ${PACKAGE_VERSION}"
    sed -i "s/^__version__ *= *[\"'].*[\"']/__version__ = \"${PACKAGE_VERSION}\"/" memcache.py
}

# =============================================================================
# CALLBACK: pre_test — install test-only dependencies not covered by the template
# =============================================================================
pre_test() {
    log_info "Installing test-only requirements"
    if [[ -f test-requirements.txt ]]; then
        python -m pip install -r test-requirements.txt
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — start memcached daemon then run tests
# The test suite requires a live memcached instance on localhost:11211.
# The daemon is started in background (-d) before pytest runs.
# =============================================================================
custom_test_command() {
    log_info "Starting memcached daemon (background, 64MB, port 11211)"
    # -d: daemonise, -m 64: 64MB memory limit, -p 11211: default port, -u root: run as root
    memcached -d -m 64 -p 11211 -u root
    log_info "Running tests"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

