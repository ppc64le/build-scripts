#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pymssql
# Version       : v2.3.13
# Source repo   : https://github.com/pymssql/pymssql
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Build Scripts Team
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pymssql"
PACKAGE_VERSION="${1:-v2.3.13}"
PACKAGE_URL="https://github.com/pymssql/pymssql"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ openssl-devel krb5-devel python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ libssl-dev libkrb5-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ libopenssl-devel krb5-devel python3-devel python3-pip"

# =============================================================================
# CALLBACK: post_clone
# Routes to the correct patch file based on version:
#   v2.2.x (< v2.3.0)   → patches/pymssql_v2.2.x.patch
#           v2.3.2       → patches/pymssql_v2.3.2.patch
#           v2.3.4       → patches/pymssql_v2.3.4.patch
#   v2.3.5 – v2.3.8     → patches/pymssql_v2.3.5_to_v2.3.8.patch
#                          + sed to pin setuptools_scm in pyproject.toml
#         >= v2.3.9      → no patch needed; only pin setuptools_scm via sed
#
# Each patch covers:
#   - pyproject.toml: pin setuptools_scm[toml] < 9.0  (where applicable)
#   - src/pymssql/_mssql.pyx: replace `long` with `int`, fix f-string brace
# =============================================================================
post_clone() {
    local version_num="${PACKAGE_VERSION#v}"
    if [[ "${version_num}" == "2.3.2" ]]; then
        log_info "Applying patch for v2.3.2..."
        git apply "${SCRIPT_DIR}/patches/pymssql_v2.3.2.patch"

    elif [[ "${version_num}" == "2.3.4" ]]; then
        log_info "Applying patch for v2.3.4..."
        git apply "${SCRIPT_DIR}/patches/pymssql_v2.3.4.patch"

    elif [[ "$(printf '%s\n' "2.3.0" "${version_num}" | sort -V | head -n1)" == "${version_num}" ]]; then
        log_info "Applying patch for v2.2.x (< v2.3.0)..."
        git apply "${SCRIPT_DIR}/patches/pymssql_v2.2.5.patch"

    elif [[ "$(printf '%s\n' "2.3.9" "${version_num}" | sort -V | head -n1)" == "${version_num}" ]] && \
         [[ "${version_num}" != "2.3.9" ]]; then
        log_info "Applying _mssql.pyx fix for v2.3.5–v2.3.8 (unclosed f-string brace)..."
        git apply "${SCRIPT_DIR}/patches/pymssql_v2.3.5_to_v2.3.8.patch"
        log_info "Pinning setuptools_scm via sed..."
        sed -i 's/"setuptools_scm\[toml\]>=5.0"/"setuptools_scm[toml]>=5.0,<9.0"/' pyproject.toml

    else
        log_info "Version >= v2.3.9 — pinning setuptools_scm via sed..."
        sed -i 's/"setuptools_scm\[toml\]>=5.0"/"setuptools_scm[toml]>=5.0,<9.0"/' pyproject.toml
    fi
}

# =============================================================================
# CALLBACK: custom_install
# pymssql cannot use `python -m build` because it relies on dev/build.py to
# download and statically link FreeTDS.  The workflow is:
#   1. Install build-time Python deps (Cython, wheel, setuptools_scm).
#   2. Run dev/build.py which downloads FreeTDS, compiles it, then builds the
#      sdist (and optionally a wheel for versions > 2.3.4).
#   3. pip-install from the local dist/ directory.
# The venv is already created and activated by the template before this runs.
#
# Versions < v2.3.4 note:
#   dev/build.py builds FreeTDS with --enable-krb5, pulling in GSSAPI symbols
#   (e.g. gss_release_name) from libgssapi_krb5.so.  The v2.2.x setup.py only
#   links -lssl and -lcrypto for Linux, leaving those symbols unresolved at
#   import time on Python 3.11+.  This is fixed in patches/pymssql_v2.2.5.patch
#   which adds -lgssapi_krb5 directly to the extension's extra_link_args.
# =============================================================================
custom_install() {
    local version_num="${PACKAGE_VERSION#v}"

    log_info "Installing Python build dependencies..."
    if [[ -f "dev/requirements-dev.txt" ]]; then
        if ! python -m pip install -r dev/requirements-dev.txt; then
            log_warn "dev/requirements-dev.txt install had warnings (non-fatal)"
        fi
    fi
    python -m pip install "cython" "setuptools_scm[toml]>=5.0,<9.0" "wheel>=0.36.2"

    log_info "Running dev/build.py with static FreeTDS..."

    local BUILD_CMD="python dev/build.py \
        --freetds-url=https://www.freetds.org/files/stable \
        --ws-dir=./freetds \
        --dist-dir=./dist \
        --with-openssl=yes \
        --enable-krb5 \
        --sdist \
        --static-freetds"

    # Add --wheel for versions > 2.3.4
    if [[ "$(printf '%s\n' "2.3.4" "${version_num}" | sort -V | head -n1)" != "${version_num}" ]]; then
        BUILD_CMD+=" --wheel"
    fi

    log_info "Build command: ${BUILD_CMD}"
    if ! eval "${BUILD_CMD}"; then
        log_error "dev/build.py failed"
        return 1
    fi

    log_info "Installing from dist/..."
    if ! python -m pip install pymssql --no-index -f dist; then
        log_error "pip install from dist/ failed"
        return 1
    fi

    # For versions <= 2.3.4 dev/build.py only produces an sdist; build the
    # wheel separately so the template's wheel-processing step has something
    # to work with.  LDFLAGS is still exported so this wheel also links correctly.
    if ! ls dist/*.whl 1>/dev/null 2>&1; then
        log_info "No wheel produced by dev/build.py, building with setup.py..."
        python setup.py bdist_wheel
    fi

    # Verify the import works before declaring success
    if ! python -c "import pymssql; print(pymssql.version_info())"; then
        log_error "pymssql import verification failed"
        return 1
    fi

    log_info "pymssql installed successfully"
    return 0
}

# =============================================================================
# CALLBACK: pre_test
# Install test dependencies and sanitise the pytest plugin set before the
# test runner fires.  Removing pytest-cov and pytest-xdist prevents crashes
# during entrypoint loading when those plugins are not fully compatible.
# =============================================================================
pre_test() {
    log_info "Installing test dependencies..."
    if [[ -f "dev/requirements-dev.txt" ]]; then
        if ! python -m pip install -r dev/requirements-dev.txt; then
            log_warn "dev/requirements-dev.txt install had warnings (non-fatal)"
        fi
    fi
    if ! python -m pip install --upgrade "pytest>=7.0"; then
        log_warn "pytest upgrade had warnings (non-fatal)"
    fi
    # Remove plugins that crash during entrypoint loading before -p flags fire
    if ! python -m pip uninstall -y pytest-cov pytest-xdist 2>/dev/null; then
        log_warn "pytest-cov/pytest-xdist were not installed, skipping uninstall"
    fi
}


# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
