#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : hdijupyterutils
# Version       : 0.20.0
# Source repo   : https://github.com/jupyter-incubator/sparkmagic
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <Sai.Kiran.Nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="hdijupyterutils"
PACKAGE_VERSION="${1:-0.20.0}"
PACKAGE_URL="https://github.com/jupyter-incubator/sparkmagic"

# Pure-Python package: PyPI ships only an sdist (no compiled extensions), so it is installed from PyPI
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — cd into the hdijupyterutils/ subdirectory.
# The sparkmagic monorepo is cloned; hdijupyterutils lives in its own subdir.
# The build and test phases must run from that subdirectory.
# =============================================================================
post_clone() {
    log_info "Changing into hdijupyterutils/ subdirectory (package lives in sparkmagic monorepo)"
    cd hdijupyterutils/
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies not provided by the template.
# mock is required by the hdijupyterutils test suite.
# The tests use the legacy `nose` package, which does not import on Python 3.12
# (the `imp` module was removed). The deprecated aliases used by the 0.20.0
# tests/sources are updated here:
#   - nose.tools.assert_equals/assert_not_equals -> assert_equal/assert_not_equal
#   - IPython.core.display.display/HTML          -> IPython.display
# The nose -> pynose swap itself happens in custom_test_command, because the
# template installs requirements.txt (which lists `nose`) after pre_test.
# NOTE: NOARCH installs the package from PyPI into site-packages, so these
# patches only take effect because the tests run from the source tree (default
# pytest import mode lets the patched clone shadow the installed copy). Do NOT
# add --import-mode=importlib to the pytest command or the patches are ignored.
# =============================================================================
pre_test() {
    log_info "Installing test dependencies: mock"
    python -m pip install mock
    log_info "Patching deprecated nose/IPython aliases for Python 3.12 compatibility"
    sed -i 's/assert_not_equals/assert_not_equal/g; s/assert_equals/assert_equal/g' \
        hdijupyterutils/tests/*.py
    sed -i 's/from IPython.core.display import/from IPython.display import/' \
        hdijupyterutils/ipythondisplay.py
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest excluding test_send_to_handler
# which requires a live HDInsight/Livy endpoint not available in CI.
# =============================================================================
custom_test_command() {
    log_info "Replacing legacy nose with pynose (nose is reinstalled by requirements.txt)"
    python -m pip install --no-deps pynose
    log_info "Running hdijupyterutils tests (excluding test_send_to_handler)"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        -k "not test_send_to_handler"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"


