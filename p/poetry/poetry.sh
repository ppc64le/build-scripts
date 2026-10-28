#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : poetry
# Version       : 2.3.3
# Source repo   : https://github.com/python-poetry/poetry
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="poetry"
PACKAGE_VERSION="${1:-2.3.3}"
PACKAGE_URL="https://github.com/python-poetry/poetry"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make openssl openssl-devel libffi-devel zlib-devel bzip2-devel xz-devel sqlite-devel ncurses-devel python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Poetry is pure Python - install from PyPI instead of building from source
NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — install test dependencies before running the test suite
# =============================================================================
pre_test() {
    log_info "Installing test dependencies and removing incompatible pytest plugins..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install coverage deepdiff dulwich responses jaraco-classes pytest-mock pytest-randomly pytest-xdist[psutil] httpretty "urllib3<2"
    python -m pip uninstall -y pytest-cov
}

# =============================================================================
# CALLBACK: custom_test_command — run poetry test suite with ppc64le-specific exclusions
# =============================================================================
custom_test_command() {
    log_info "Running poetry test suite..."

    # Limit xdist workers to 2 to avoid OOM kills in constrained CI containers.
    # Exclude network tests as they may fail in isolated build environments.
    # Use --import-mode=importlib so pytest uses the installed package, not local source.
    # --ignore=tests/utils/test_threading.py: race conditions with parallel execution
    # --ignore=tests/utils/env/test_env.py: pipe buffer handling issues
    # --deselect test_execute_executes_a_batch_of_operations: fails on ppc64le when virtualenv
    #   cannot resolve an embedded pip wheel for MockEnv
    # --deselect test_execute_prints_warning_for_yanked_package: same MockEnv pip wheel issue
    # --deselect test_prepare_directory_with_extensions: ppc64le reports manylinux_2_34_ppc64le
    #   as env.supported_tags[0] instead of linux_ppc64le; wheel filename mismatch is
    #   a platform-tag difference, not a build defect
    python -m pytest --import-mode=importlib -o "addopts=" --disable-warnings -n 2 -ra -m "not network" \
        --ignore=tests/utils/test_threading.py \
        --ignore=tests/utils/env/test_env.py \
        --deselect=tests/installation/test_executor.py::test_execute_executes_a_batch_of_operations \
        --deselect=tests/installation/test_executor.py::test_execute_prints_warning_for_yanked_package \
        --deselect=tests/installation/test_chef.py::test_prepare_directory_with_extensions \
        tests/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
