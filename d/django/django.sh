#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : django
# Version       : 5.0.7
# Source repo   : https://github.com/django/django
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="django"
PACKAGE_VERSION="${1:-5.0.7}"
PACKAGE_URL="https://github.com/django/django"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip libmemcached-awesome-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — Install test dependencies before running the test suite
# =============================================================================
pre_test() {
    log_info "Installing test requirements..."
    python -m pip install -r tests/requirements/py3.txt
    python -m pip install "tblib<3.2"
    if [ "${PACKAGE_VERSION}" = "5.0.7" ]; then
        python -m pip install "asgiref==3.8.1"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — Run the Django test suite with custom settings
# =============================================================================
custom_test_command() {
    log_info "Running custom test command"
    cd tests/
    python runtests.py --settings=test_sqlite \
        --exclude-tag=gis \
        -v 2
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
