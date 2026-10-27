#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : shapely
# Version       : 1.8.5
# Source repo   : https://github.com/shapely/shapely.git
# Tested on     : UBI 8.10
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandan.Abhyankar@ibm.com
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: shapely_ubi_8.10.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="shapely"
PACKAGE_VERSION="${1:-1.8.5}"
PACKAGE_URL="https://github.com/shapely/shapely.git"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-c++ gcc-gfortran.ppc64le git openblas openblas-devel python3.11-devel python3.11-pip python311"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:/geos/build/lib:/usr/lib:/usr/lib64:$LD_LIBRARY_PATH
export GEOS_CONFIG=/geos/build/tools/geos-config

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# pip3.11 install Cython pytest hypothesis build
# git clone https://github.com/libgeos/geos
# cd geos
# git checkout 3.11.1
# mkdir build
# cd build
# cmake ..
# if !(make)
#   echo "Failed to build the dependent GEOS package"
# if !(ctest)
#   echo "Failed to validate the dependent GEOS package"
# cd ../../
# git submodule update --init
# export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:/geos/build/lib:/usr/lib:/usr/lib64:$LD_LIBRARY_PATH
# export GEOS_CONFIG=/geos/build/tools/geos-config
# GEOS_CONFIG=/geos/build/tools/geos-config python3.11 -m build
# if [ $? == 0 ]; then
# python3.11 -m pytest tests/test_geometry_base.py
# if [ $? == 0 ]; then

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
