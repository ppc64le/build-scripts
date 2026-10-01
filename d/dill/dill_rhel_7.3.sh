#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : dill
# Version       : 0.4.1
# Source repo   : https://github.com/uqfoundation/dill/
# Tested on     : rhel_7.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Archa Bhandare <barcha@us.ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="dill"
PACKAGE_VERSION="${1:-0.4.1}"  # Updated from 0.2.5 (not available, >5 years old)
PACKAGE_URL="https://github.com/uqfoundation/dill/"
PACKAGE_AVAILABLE_TAGS="0.4.1,0.4.0,0.3.9,0.3.8,dill-0.3.7,dill-0.3.6,dill-0.3.5.1,dill-0.3.5,dill-0.3.4"  # Available git tags for fallback testing

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="build-essential deltarpm gdal-bin git libgdal-dev libproj-dev python-setuptools"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export DEBIAN_FRONTEND=noninteractive

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# export DEBIAN_FRONTEND=noninteractive
# git clone https://github.com/uqfoundation/dill/
# cd dill/
# sudo python setup.py install && sudo python setup.py test

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
