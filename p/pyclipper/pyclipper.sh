#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyclipper
# Version       : 1.4.0
# Source repo   : https://github.com/fonttools/pyclipper
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyclipper"
PACKAGE_VERSION="${1:-1.4.0}"
PACKAGE_URL="https://github.com/fonttools/pyclipper"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel python3-pip sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# pre_build: Install Cython, setuptools_scm, and setuptools_scm_git_archive
#            for .pyx compilation. pyclipper's setup.py requires all three
#            via setup_requires and use_scm_version.
# =============================================================================
pre_build() {
    log_info "Installing pyclipper build dependencies..."

    # pyclipper's setup.py lists cython>=0.28 and setuptools_scm>=1.11.1 in
    # setup_requires; setuptools_scm_git_archive is also required by
    # use_scm_version when building from a git checkout
    python -m pip install "cython>=0.28" setuptools_scm setuptools_scm_git_archive
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
