#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyyaml
# Version       : 6.0.3
# Source repo   : https://github.com/yaml/pyyaml
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyyaml"
PACKAGE_VERSION="${1:-6.0.3}"
PACKAGE_URL="https://github.com/yaml/pyyaml"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel libyaml-devel ninja-build"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install Cython required for the C extension
# pyyaml 6.0.2+ requires Cython>=3.0; earlier versions need Cython<3
# =============================================================================
pre_build() {
    log_info "Installing build dependencies for pyyaml C extension..."
    local pkg_ver=(${PACKAGE_VERSION//v/})
    pkg_ver=(${pkg_ver//./ })
    if [[ ${pkg_ver[0]} -gt 6 ]] || \
       [[ ${pkg_ver[0]} -eq 6 && ${pkg_ver[1]} -gt 0 ]] || \
       [[ ${pkg_ver[0]} -eq 6 && ${pkg_ver[1]} -eq 0 && ${pkg_ver[2]} -ge 2 ]]; then
        log_info "Installing Cython>=3.0 for pyyaml ${PACKAGE_VERSION#v}"
        python -m pip install "cython>=3.0"
    else
        log_info "Installing Cython<3.0 for pyyaml ${PACKAGE_VERSION#v}"
        python -m pip install "cython<3.0.0"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — run pyyaml tests
# pyyaml 6.0 and 6.0.1 do not ship tests/lib/conftest.py which registers
# pytest_generate_tests to parametrize tests over data files in tests/data/;
# without it all file-based fixtures (canonical_filename, data_filename etc.)
# fail with "fixture not found" — a smoke import test is used instead.
#
# pyyaml 6.0.2+ ships conftest.py and introduced tests/legacy_tests/ whose
# conftest.py does "from test_appliance import ..." — test_appliance lives in
# tests/lib/ which is not on sys.path by default, causing ModuleNotFoundError
# during collection. Setting PYTHONPATH=tests/legacy_tests makes test_appliance
# importable so collection succeeds.
#
# --import-mode=importlib prevents pytest from shadowing the installed package
# with the source tree; -o "addopts=" clears any --cov flags set in
# pyproject.toml that would fail on ppc64le due to missing coverage plugins.
# =============================================================================
custom_test_command() {
    log_info "Running pyyaml tests..."
    if [[ "${PACKAGE_VERSION}" == "6.0" || "${PACKAGE_VERSION}" == "6.0.1" ]]; then
        log_info "pyyaml ${PACKAGE_VERSION} has no conftest.py — running smoke test..."
        python -c "import yaml; print('yaml version:', yaml.__version__)"
        return
    fi
    PYTHONPATH="${PWD}/tests/legacy_tests${PYTHONPATH:+:$PYTHONPATH}" \
    python -m pytest --import-mode=importlib -o "addopts=" tests/ -v
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
