#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ibm-cos-sdk-python-core
# Version       : 2.13.4
# Source repo   : https://github.com/ibm/ibm-cos-sdk-python-core
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ibm-cos-sdk-python-core"
PACKAGE_VERSION="${1:-2.13.4}"
PACKAGE_URL="https://github.com/ibm/ibm-cos-sdk-python-core"

NOARCH="true"
SETUPTOOLS_VERSION="<82"
PYPI_NAME="ibm-cos-sdk-core"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS=""
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command — smoke-import only; full test suite skipped
# in parity with Intel due to missing fixture/lock files (issue #25)
# =============================================================================
custom_test_command() {
    log_info "Running import smoke test for ${PACKAGE_NAME}"
    python -c "import ibm_botocore; print('ibm_botocore version:', ibm_botocore.__version__)"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

