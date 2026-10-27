#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : zstandard
# Version       : 0.22.0
# Source repo   : https://github.com/indygreg/python-zstandard
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="zstandard"
PACKAGE_VERSION="${1:-0.22.0}"
PACKAGE_URL="https://github.com/indygreg/python-zstandard"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git libzstd-devel make pkg-config python3 python3-devel.ppc64le sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# zstandard 0.22.0 pyproject.toml declares exact build-system requires:
#   requires = ["cffi==1.16.0", "setuptools==68.2.2", "wheel==0.41.2"]
# python -m build --no-isolation (used by the template) validates that the
# installed versions in the build venv match exactly. Any mismatch causes a
# "ERROR Unmet dependencies" failure and exits with code 1.
# SETUPTOOLS_VERSION is consumed by python.sh to install
# "setuptools${SETUPTOOLS_VERSION}" — setting it to "==68.2.2" satisfies
# the exact pin declared in pyproject.toml.
SETUPTOOLS_VERSION="==68.2.2"

pre_build() {
    # cffi and wheel must match the exact versions declared in zstandard's
    # pyproject.toml [build-system] requires. python -m build --no-isolation
    # checks the installed versions against these declarations and fails if
    # there is any mismatch. The template installs a newer wheel by default,
    # so we downgrade/pin both here before the build runs.
    local lang_ver=(${LANGUAGE_VERSION//./ })

    if [[ ${lang_ver[0]} -eq 3 && ${lang_ver[1]} -ge 13 ]]; then
        log_info "Python ${LANGUAGE_VERSION} detected: installing cffi>=1.17.0 (cffi 1.16.0 does not support Python 3.13+)..."
        pip install "cffi>=1.17.0" "wheel==0.41.2"
    else
        log_info "Python ${LANGUAGE_VERSION} detected: installing exact build-system dependencies required by zstandard's pyproject.toml..."
        pip install "cffi==1.16.0" "wheel==0.41.2"
    fi
}

pre_test() {
    # setuptools is required by the pyproject.toml build backend
    # (setuptools.build_meta). The test venv is created with only pip + pytest
    # by the template (python.sh line 525), so setuptools is absent by default.
    # Without it, pip install --no-build-isolation . fails with:
    #   BackendUnavailable: Cannot import 'setuptools.build_meta'
    log_info "Installing setuptools and wheel into test venv..."
    pip install --upgrade setuptools wheel
}

custom_test_command() {
    log_info "Running zstandard test suite..."
    # Build the C extension module in-place so tests can import it
    python setup.py build_ext --inplace
    # --import-mode=importlib is required because pytest is run from inside the
    # source directory. Without it, Python's default import prepends the current
    # directory to sys.path, causing `import zstandard` to resolve to the source
    # folder (zstandard/) instead of the installed package. The source folder has
    # no compiled C extension (backend_c.so), which causes:
    #   ModuleNotFoundError: No module named 'zstandard.backend_c'
    # importlib mode bypasses sys.path manipulation so the installed package
    # (including the compiled .so) is imported correctly.
    python -m pytest --import-mode=importlib -v tests/
}
# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

