#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : numexpr
# Version       : 2.10.2
# Source repo   : https://github.com/pydata/numexpr
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Vikram Kuppala <sai.vikram.kuppala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="numexpr"
PACKAGE_VERSION="${1:-2.10.2}"
PACKAGE_URL="https://github.com/pydata/numexpr"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git openssl-devel bzip2-devel libffi-devel zlib-devel python3-devel python3-pip openblas-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — read setuptools requirement from pyproject.toml
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
            log_info "No setuptools pin found in pyproject.toml — using template default"
        fi
    else
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — parse pyproject.toml and install build-system requirements
# Runs inside the cloned repo (.venv-build active), so pyproject.toml is
# available here. We use tomli to install build-system requirements directly
# (ml-dtypes approach from PR #377).
# =============================================================================
pre_build() {
    log_info "Installing tomli and build-system requirements from pyproject.toml..."
    # tomllib is built-in only from Python 3.11+; tomli covers older versions
    python -m pip install tomli

    if [[ -f "pyproject.toml" ]]; then
        # Install each [build-system].requires entry via subprocess so environment
        # markers are handled correctly (ml-dtypes approach from PR #377).
        # check=True ensures a failed dep install surfaces immediately in the logs.
        log_info "Extracting and installing build-system requirements from pyproject.toml..."
        python -c "
import tomli
import subprocess
import sys

with open('pyproject.toml', 'rb') as f:
    requires = tomli.load(f).get('build-system', {}).get('requires', [])
for req in requires:
    subprocess.run([sys.executable, '-m', 'pip', 'install', req], check=True)
" || log_warn "Failed to install some build requirements"
    else
        log_warn "pyproject.toml not found, using fallback numpy 1.x for build"
        python -m pip install "numpy>=1.19.0,<2.0.0"
    fi
}

# =============================================================================
# CALLBACK: pre_test — re-install tomli in fresh test venv so pyproject.toml
# parsing in custom_test_command works (.venv-test does not inherit .venv-build)
# =============================================================================
pre_test() {
    log_info "Installing tomli and setuptools/wheel into test venv..."
    # .venv-test is a fresh venv — nothing from .venv-build carries over
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install tomli
    # pytest-cov and pytest-xdist crash via setuptools entrypoints before -p no: flags are processed
    python -m pip uninstall -y pytest-cov pytest-xdist 2>/dev/null 
}

# =============================================================================
# CALLBACK: custom_test_command — derive numpy test version from pyproject.toml,
# cap at <2.1.0 for v2.10.x ABI compatibility, run via --pyargs from a temp dir
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies..."

    # Derive NUMPY_TEST_VERSION from [project].dependencies.
    #   - present (>=2.10.x)  use the declared runtime constraint
    #   - absent  (<=2.9.x)   fallback to numpy>=1.19.0,<2.0.0 (1.x ABI)
    local NUMPY_TEST_VERSION
    if [[ -f "pyproject.toml" ]]; then
        NUMPY_TEST_VERSION=$(python -c "
import tomli
with open('pyproject.toml', 'rb') as f:
    data = tomli.load(f)
deps = data.get('project', {}).get('dependencies', [])
numpy_dep = next((d for d in deps if d.lower().startswith('numpy')), None)
print(numpy_dep if numpy_dep else 'numpy>=1.19.0,<2.0.0')
" 2>/dev/null || echo "numpy>=1.19.0,<2.0.0")

        # v2.10.x C extension was compiled against numpy 2.0 ABI but its
        # [project].dependencies only declares 'numpy>=1.23.0' (no upper bound),
        # so pip resolves to numpy 2.4.x which causes a Fatal C-level crash.
        # v2.11.0+ fixed this — their C extension is compatible with numpy 2.x.
        # Detect v2.10.x directly from PACKAGE_VERSION and cap test numpy at <2.1.0.
        _minor="${PACKAGE_VERSION#v}"; _minor="${_minor#*.}"; _minor="${_minor%%.*}"
        if [[ "$_minor" -eq 10 ]]; then
            log_info "v2.10.x detected — capping NUMPY_TEST_VERSION at <2.1.0 (ABI compatibility)"
            NUMPY_TEST_VERSION="numpy>=2.0.0,<2.1.0"
        fi
        unset _minor
    else
        NUMPY_TEST_VERSION="numpy>=1.19.0,<2.0.0"
    fi

    log_info "Numpy test version: ${NUMPY_TEST_VERSION}"
    python -m pip install "${NUMPY_TEST_VERSION}"
    # Pin pytest<8 — numexpr uses yield-based test fixtures incompatible with pytest>=8
    python -m pip install "pytest>=7.0.0,<8.0.0"

    log_info "Running numexpr tests..."

    # Run tests from a temp dir so pytest cannot accidentally discover conftest.py
    # from the source tree via rootdir detection, which would try to import the
    # uncompiled source numexpr (no .so) and fail with ModuleNotFoundError.
    # --pyargs finds numexpr in site-packages; mktemp gives pytest an empty rootdir.
    # =====================================================================
    # EXCLUSION NOTE: 'test_numexpr_max_threads_empty_string' and
    # 'test_omp_num_threads_empty_string' are excluded because they
    # programmatically clear out thread environmental variables to test
    # fallback behavior. On massive multi-core systems (e.g., our 144-core
    # topology), NumExpr automatically caps its fallback pool at 8 threads,
    # causing assertions comparing it to physical core counts to fail
    # (144 != 8).
    #
    # v2.10.x + Python 3.14+: test_refcount (CPython 3.14 changed refcount
    # semantics), test_simple_expr / test_rational_expr / test_changing_nthreads
    # (Python 3.14 contextlib adds an extra frame that breaks sys._getframe()
    # variable lookup inside unittest.TestCase — fixed upstream in v2.11.0).
    # =====================================================================
    local _exclude_filter="test_numexpr_max_threads_empty_string or test_omp_num_threads_empty_string"
    _pyver=$(python -c "import sys; print(sys.version_info.major * 100 + sys.version_info.minor)")
    _minor_chk="${PACKAGE_VERSION#v}"; _minor_chk="${_minor_chk#*.}"; _minor_chk="${_minor_chk%%.*}"
    if [[ "$_pyver" -ge 314 ]] && [[ "$_minor_chk" -eq 10 ]]; then
        _exclude_filter="${_exclude_filter} or test_refcount or test_simple_expr or test_rational_expr or test_changing_nthreads"
    fi
    unset _pyver _minor_chk

    local test_dir
    test_dir=$(mktemp -d)
    cd "${test_dir}"

    python -m pytest --pyargs numexpr \
        -o "addopts=" \
        --disable-warnings \
        -k "not (${_exclude_filter})"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
