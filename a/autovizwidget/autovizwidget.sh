#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : autovizwidget
# Version       : 0.23.0
# Source repo   : https://github.com/jupyter-incubator/sparkmagic
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="autovizwidget"
PACKAGE_VERSION="${1:-0.23.0}"
PACKAGE_URL="https://github.com/jupyter-incubator/sparkmagic"

# autovizwidget lives inside the sparkmagic monorepo; clone the monorepo root
CLONE_DIR="sparkmagic"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — cd into autovizwidget subdirectory
# autovizwidget is a subdirectory of the sparkmagic monorepo.
# clone_repository() cd's into the repo root (sparkmagic/), so we step down
# into the autovizwidget/ subdirectory where setup.py lives.
# python -m build falls back to setuptools automatically when no pyproject.toml
# is present (PEP 517), so no injection is needed.
# =============================================================================
post_clone() {
    cd autovizwidget
    log_info "Changed into monorepo subdirectory: $(pwd)"
    if [[ -f "pyproject.toml" ]]; then
        setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
        if [[ -n "$setuptools_req" ]]; then
            SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
            SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
            log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
        else
            log_info "No setuptools pin found in pyproject.toml — using template default"
        fi
    else
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies
# Runtime deps (plotly, pandas, ipywidgets, ...) are installed by the template
# from requirements.txt, so only test-only dependencies are needed here.
# 0.20.x tests are written for nose, which is broken on Python 3.12 (the 'imp'
# module was removed). pynose is the maintained drop-in replacement.
# =============================================================================
pre_test() {
    if [[ "${PACKAGE_VERSION}" == 0.20.* ]]; then
        python -m pip install mock pynose
    else
        python -m pip install mock
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — run the tests
#
# 0.20.x: tests use nose's @with_setup, which pytest does not honour, so they
#   are run with the nose runner (pynose). Only test_encodingwidget.py and
#   test_sparkevents.py can run; the other test files cannot be imported:
#     - test_autovizwidget.py imports assert_equals, removed in Python 3.12
#     - test_plotlygraphrenderer.py, test_plotlygraphs.py, test_utils.py import
#       the source modules, which import DataError from pandas.core.base /
#       pandas.core.groupby; pandas 2.x moved it to pandas.errors
#       (fixed upstream in 0.22.0)
#
# 0.22.0+: run pytest, ignoring test_utils.py entirely. That file uses
#   pd.to_datetime() and pd.date_range(), both of which segfault inside
#   pandas' compiled C extension when pandas is built from source on ppc64le
#   against numpy 2.x. The crashes happen in the tests' own setup calls,
#   before any autovizwidget code runs, so this is not an autovizwidget defect.
#   The other 21 tests still run.
#   --ignore paths are relative to the current directory (the autovizwidget/
#   subdirectory), unlike --deselect IDs, which are relative to the rootdir.
# =============================================================================
custom_test_command() {
    if [[ "${PACKAGE_VERSION}" == 0.20.* ]]; then
        python -m nose -v \
            autovizwidget/tests/test_encodingwidget.py \
            autovizwidget/tests/test_sparkevents.py
    else
        python -m pytest --import-mode=importlib -o "addopts=" \
            --ignore=autovizwidget/tests/test_utils.py
    fi
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_WHEEL="true"
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
