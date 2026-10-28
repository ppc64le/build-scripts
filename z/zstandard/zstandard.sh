#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : zstandard
# Version       : 0.25.0
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
PACKAGE_VERSION="${1:-0.25.0}"
PACKAGE_URL="https://github.com/indygreg/python-zstandard"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake git libzstd-devel make pkg-config python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — detect SETUPTOOLS_VERSION from pyproject.toml; patch
#           license field format for setuptools >=77 compatibility
# =============================================================================
post_clone() {
    log_info "Reading setuptools version requirement from pyproject.toml"
    if [[ -f "pyproject.toml" ]]; then
        setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
        if [[ -n "$setuptools_req" ]]; then
            SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
            SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
            log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
        else
            SETUPTOOLS_VERSION="<82"
            log_info "No setuptools pin found in pyproject.toml — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
        fi
    else
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi

    # Fix pyproject.toml license field format if pyproject.toml defines [project].
    # Newer versions (e.g. 0.25.0) use `license = "BSD-3-Clause"` (string) in pyproject.toml,
    # but setuptools >=77 expects the license to be declared in the dynamic array and provided
    # via setup.py. Older versions (e.g. 0.19.0) already have license="BSD" in setup.py and
    # no [project] section.
    if grep -q '^\[project\]' pyproject.toml 2>/dev/null; then
        log_info "Fixing pyproject.toml license field for setuptools >=77..."
        sed -i 's/dynamic = \["version"\]/dynamic = ["version", "license"]/' pyproject.toml
        sed -i '/^license = "BSD-3-Clause"$/d' pyproject.toml

        if ! grep -q 'license=' setup.py 2>/dev/null; then
            log_info "Patching setup.py to include license from LICENSE file..."
            test_suite_line=$(grep -n 'test_suite="tests"' setup.py | cut -d: -f1)
            if [[ -n "$test_suite_line" ]]; then
                sed -i "${test_suite_line}a\\    license=open(\"LICENSE\").read()," setup.py
            fi
        fi
    fi
}

# =============================================================================
# CALLBACK: pre_build — install cffi matching the version range declared in
#           zstandard's pyproject.toml [build-system] requires
# =============================================================================
pre_build() {
    local py_minor
    py_minor=$(python -c "import sys; print(sys.version_info[1])")

    if [[ ${py_minor} -ge 14 ]]; then
        log_info "Python >= 3.14 detected: installing cffi>=2.0.0b (required for Python 3.14+)..."
        python -m pip install "cffi>=2.0.0b"
    else
        log_info "Python < 3.14 detected: installing cffi~=1.17 (required by zstandard 0.25.0 pyproject.toml)..."
        python -m pip install "cffi~=1.17"
    fi
}

# =============================================================================
# CALLBACK: pre_test — install build backend and cffi into the test venv.
#           .venv-test is a fresh environment; setuptools and cffi are absent
#           by default, causing 'Cannot import setuptools.build_meta' and
#           import failures for the compiled C extension.
# =============================================================================
pre_test() {
    log_info "Installing setuptools, wheel, and pip into test venv..."
    python -m pip install --upgrade pip setuptools wheel

    local py_minor
    py_minor=$(python -c "import sys; print(sys.version_info[1])")

    if [[ ${py_minor} -ge 14 ]]; then
        log_info "Python >= 3.14 detected: installing cffi>=2.0.0b for test venv..."
        python -m pip install "cffi>=2.0.0b"
    else
        log_info "Python < 3.14 detected: installing cffi~=1.17 for test venv..."
        python -m pip install "cffi~=1.17"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — build C extension in-place then run tests.
#           --import-mode=importlib prevents the source directory (zstandard/)
#           from shadowing the installed package; without it pytest resolves
#           `import zstandard` to the source folder which lacks backend_c.so,
#           causing: ModuleNotFoundError: No module named 'zstandard.backend_c'
# =============================================================================
custom_test_command() {
    log_info "Building C extension in-place for test run..."
    python -m pip install --no-build-isolation -e .

    log_info "Running zstandard test suite..."
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        -v tests/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
