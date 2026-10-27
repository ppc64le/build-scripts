#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : patroni
# Version       : 3.3.0
# Source repo   : https://github.com/zalando/patroni
# Tested on     : UBI 8.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth<sethp@us.ibm.com> Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: patroni_ubi_8.3.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="patroni"
PACKAGE_VERSION="${1:-3.3.0}"
PACKAGE_URL="https://github.com/zalando/patroni"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS=""
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export PACKAGE_URL=${PACKAGE_URL:-"https://github.com/zalando/patroni"}
export PYVERSION=${PYVERSION:-"39"}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# export PACKAGE_URL=${PACKAGE_URL:-"https://github.com/zalando/patroni"}
# export PYVERSION=${PYVERSION:-"39"}
# OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
# if [ $1 = "clean" ]; then
#     rm -rf ~/patroni*
# echo "creating virtual environment  at ~/${PACKAGE_NAME}_venv_PY${PYVERSION}"
# python3 -m venv ~/${PACKAGE_NAME}_venv_PY${PYVERSION}
# source  ~/${PACKAGE_NAME}_venv_PY${PYVERSION}/bin/activate
# pip install --upgrade pip
# pip install Cython wheel
# pip install -r requirements.txt
# pip install -r requirements.dev.txt
# python .github/workflows/install_deps.py
# python setup.py bdist_wheel

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
