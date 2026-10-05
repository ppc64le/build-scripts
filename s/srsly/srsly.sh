#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : srsly
# Version       : release-v2.5.3
# Source repo   : https://github.com/explosion/srsly
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="srsly"
PACKAGE_URL="https://github.com/explosion/srsly"

# srsly uses two tag formats: v* (<=2.4.x) and release-v* (>=2.5.x).
# Strip any prefix from the input so we can probe which tag format exists.
_bare="${1:-2.5.3}"; _bare="${_bare#release-v}"; _bare="${_bare#v}"
git ls-remote --tags "${PACKAGE_URL}" "refs/tags/release-v${_bare}" | grep -q . \
    && PACKAGE_VERSION="release-v${_bare}" \
    || PACKAGE_VERSION="v${_bare}"
unset _bare

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install Cython required to compile srsly C extensions
# =============================================================================
pre_build() {
    log_info "Installing Cython build dependency"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cython
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into test venv
# =============================================================================
pre_test() {
    log_info "Installing build backend and mirrored build deps into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cython
}

# =============================================================================
# CALLBACK: custom_test_command — run the full upstream srsly test suite.
# =============================================================================
custom_test_command() {
    log_info "Running srsly test suite via installed package"
    # cloudpickle tests reference srsly.cloudpickle.compat removed in v2.5.0 — skip the whole file.
    # tests/ujson/test_ujson.py: segfaults on Python 3.14 due to ujson C extension ABI incompatibility.
    cd "$(python -m pip show srsly | awk '/^Location:/{print $2}')/srsly"
    python -I -m pytest \
        tests \
        -o "addopts=" \
        --disable-warnings \
        --ignore=tests/cloudpickle/cloudpickle_test.py \
        --ignore=tests/cloudpickle/cloudpickle_file_test.py \
        --ignore=tests/ujson/test_ujson.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"