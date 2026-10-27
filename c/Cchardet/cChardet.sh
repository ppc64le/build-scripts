#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cChardet
# Version       : 2.2.0-alpha.2
# Source repo   : https://github.com/PyYoshi/cChardet
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cChardet"
PACKAGE_VERSION="${1:-2.2.0-alpha.2}"
PACKAGE_URL="https://github.com/PyYoshi/cChardet"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS=""
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

pre_build() {
    # pyproject.toml build-system.requires lists Cython; install it here so
    # python -m build --no-isolation can invoke cython on _cchardet.pyx.
    log_info "Installing Cython build dependency"
    python -m pip install "cython>=3.0.10"
    # Generate .cpp from .pyx before the build step compiles it.
    # --cplus is required because setup.py declares language="c++".
    log_info "Generating C++ source from .pyx"
    python -m cython -3 src/cchardet/_cchardet.pyx --cplus
}


# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
