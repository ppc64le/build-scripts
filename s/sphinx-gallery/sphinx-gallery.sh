#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sphinx-gallery
# Version       : v0.9.0
# Source repo   : https://github.com/sphinx-gallery/sphinx-gallery
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Atharv Phadnis <Atharv.Phadnis@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sphinx-gallery"
PACKAGE_VERSION="${1:-v0.9.0}"
PACKAGE_URL="https://github.com/sphinx-gallery/sphinx-gallery"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc git python3 python3-devel python3-pytest"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# OPTIONAL: Build/test customizations
# =============================================================================
pre_test() {
    # setuptools:  re-provides distutils removed in Python 3.12; required by
    #              sphinx_gallery/scrapers.py (distutils.version.LooseVersion)
    # sphinx<7.3:  sphinx.util.status_iterator removed in Sphinx 7.3
    #              (moved to sphinx.util.display); sphinx_compatibility.py needs it
    # pytest<8:    pytest 8 dropped startdir from pytest_report_header hookspec;
    #              conftest.py declares it and raises PluginValidationError on pytest>=8
    # matplotlib, pillow: required by the test suite for image generation
    python -m pip install 'sphinx>=3.0,<7.3' 'pytest<8' matplotlib pillow
}

custom_test_command() {
    # test_full.py:         requires a full Sphinx build environment
    # test_full_noexec.py:  builds tinybuild/ which lists jupyterlite_sphinx in
    #                       conf.py extensions; not installed in the test venv
    # test_docs_resolv.py:  makes live HTTP requests (timeout in isolated build env)
    # test_load_style.py:   asserts 'type="text/css"' in generated HTML; newer Sphinx
    #                       dropped that attribute from <link> tags
    # TestLoggingTee:       all tests assert on Sphinx verbose() call counts that
    #                       changed in Sphinx>=7; incompatible with sphinx-gallery
    #                       v0.9.0 pinned to sphinx<7.3
    local tests_dir
    tests_dir="$(pwd)/sphinx_gallery/tests"
    python -m pytest "${tests_dir}" \
        -o "addopts=" \
        --ignore="${tests_dir}/test_full.py" \
        --ignore="${tests_dir}/test_full_noexec.py" \
        --ignore="${tests_dir}/test_docs_resolv.py" \
        --ignore="${tests_dir}/test_load_style.py" \
        -k "not TestLoggingTee" \
        -x -q
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

