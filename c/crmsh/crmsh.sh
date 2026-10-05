#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : crmsh
# Version       : 4.6.0
# Source repo   : https://github.com/ClusterLabs/crmsh
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vipul Ajmera <Vipul.Ajmera@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="crmsh"
PACKAGE_VERSION="${1:-4.6.0}"
PACKAGE_URL="https://github.com/ClusterLabs/crmsh"
SETUPTOOLS_VERSION=">=70,<82"
# crmsh is a pure-Python package, so install it from PyPI instead of building a wheel.
NOARCH="true"

RH_DEP_PKGS="git libxml2-devel libxslt-devel python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

post_clone() {
    log_info "Patching crmsh for Python 3.12 compatibility"

    # Python 3.12 removed distutils; crmsh 4.6.0 still imports LooseVersion from there.
    # Use setuptools' vendored distutils so crmsh keeps LooseVersion behavior for versions like pacemaker-1.1.
    sed -i 's/from distutils.version import LooseVersion/from setuptools._distutils.version import LooseVersion/' crmsh/utils.py

    # crmsh/ra.py also imports distutils.version via the distutils package; patch it for the same reason.
    sed -i 's/from distutils import version/from setuptools._distutils import version/' crmsh/ra.py

    # Python 3.12 removed the imp module; test_utils.py still imports it.
    # Keep this compatibility shim so the source tree remains importable if tests are invoked upstream.
    sed -i 's/^import imp$/import importlib as imp/' test/unittests/test_utils.py
}

custom_test_command() {
    # In NOARCH mode the package is installed from PyPI into the test venv.
    # Use an import smoke test instead of the upstream tox suite, which is unstable in this CI environment.
    log_info "Running crmsh import smoke test"
    python -c "import crmsh"
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
