#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pgvector
# Version       : v0.4.2
# Source repo   : https://github.com/pgvector/pgvector-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pgvector"
PACKAGE_VERSION="${1:-v0.4.2}"
PACKAGE_URL="https://github.com/pgvector/pgvector-python"

# =============================================================================
# Artifact dependencies
# =============================================================================
BUILD_DEPS=${BUILD_DEPS:-"numpy:v2.2.5 scipy:v1.17.1"}

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ gcc-gfortran make python3-devel openblas-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# HELPER: install NumPy from the artifact instead of PyPI
# =============================================================================
install_numpy() {
    local python_abi numpy_wheel=""
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    log_info "Looking for NumPy artifact wheel matching Python ABI ${python_abi}"
    if [[ -n "${NUMPY_PREFIX:-}" ]]; then
        numpy_wheel=$(find "${NUMPY_PREFIX}" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    fi

    if [[ -z "${numpy_wheel}" ]]; then
        log_warn "No NumPy ${python_abi} wheel found in artifact (NUMPY_PREFIX=${NUMPY_PREFIX:-<unset>}) — falling back to artifact PYTHONPATH"
        if ! python -c "import numpy; print('NumPy version:', numpy.__version__)"; then
            log_error "NumPy artifact is not importable from ${NUMPY_PREFIX:-<unset>}"
        fi
    else
        log_info "Installing NumPy wheel from artifact: ${numpy_wheel}"
        python -m pip install --force-reinstall --no-deps "${numpy_wheel}"

        local numpy_artifact_site
        numpy_artifact_site="${NUMPY_PREFIX}/lib/python$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")/site-packages"
        log_info "Removing artifact site-packages from PYTHONPATH after wheel install: ${numpy_artifact_site}"
        while [[ "${PYTHONPATH:-}" == "${numpy_artifact_site}" || "${PYTHONPATH:-}" == "${numpy_artifact_site}:"* ]]; do
            if [[ "${PYTHONPATH}" == "${numpy_artifact_site}" ]]; then
                unset PYTHONPATH
                break
            fi
            export PYTHONPATH="${PYTHONPATH#${numpy_artifact_site}:}"
        done
        python -c "import numpy; print('NumPy import path:', numpy.__file__)"
    fi
}

# =============================================================================
# HELPER: install SciPy from the artifact instead of PyPI
# =============================================================================
install_scipy() {
    local python_abi scipy_wheel=""
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    log_info "Looking for SciPy artifact wheel matching Python ABI ${python_abi}"
    if [[ -n "${SCIPY_PREFIX:-}" ]]; then
        scipy_wheel=$(find "${SCIPY_PREFIX}" -name "scipy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    fi

    if [[ -z "${scipy_wheel}" ]]; then
        log_warn "No SciPy ${python_abi} wheel found in artifact (SCIPY_PREFIX=${SCIPY_PREFIX:-<unset>}) — falling back to artifact PYTHONPATH"
        if ! python -c "import scipy; print('SciPy version:', scipy.__version__)"; then
            log_error "SciPy artifact is not importable from ${SCIPY_PREFIX:-<unset>}"
            return 1
        fi
    else
        log_info "Installing SciPy wheel from artifact: ${scipy_wheel}"
        python -m pip install --force-reinstall --no-deps "${scipy_wheel}"

        local scipy_artifact_site
        scipy_artifact_site="${SCIPY_PREFIX}/lib/python$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")/site-packages"
        log_info "Removing artifact site-packages from PYTHONPATH after wheel install: ${scipy_artifact_site}"
        while [[ "${PYTHONPATH:-}" == "${scipy_artifact_site}" || "${PYTHONPATH:-}" == "${scipy_artifact_site}:"* ]]; do
            if [[ "${PYTHONPATH}" == "${scipy_artifact_site}" ]]; then
                unset PYTHONPATH
                break
            fi
            export PYTHONPATH="${PYTHONPATH#${scipy_artifact_site}:}"
        done
        python -c "import scipy; print('SciPy import path:', scipy.__file__)"
    fi
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies for pgvector"
    python -m pip install --upgrade pip wheel
    install_numpy
    install_scipy
    python -m pip install \
        pytest \
        pytest-cov \
        pytest-xdist \
        pytest-asyncio \
        asyncpg \
        django \
        peewee \
        pg8000 \
        psycopg \
        psycopg2-binary \
        sqlalchemy \
        sqlmodel
}

# =============================================================================
# CALLBACK: custom_test_command — skip database-dependent tests
# =============================================================================
custom_test_command() {
    log_info "Running tests with database-dependent tests skipped"
    python -m pytest tests/ \
        --ignore=tests/test_asyncpg.py \
        --ignore=tests/test_django.py \
        --ignore=tests/test_peewee.py \
        --ignore=tests/test_pg8000.py \
        --ignore=tests/test_psycopg.py \
        --ignore=tests/test_psycopg2.py \
        --ignore=tests/test_sqlalchemy.py \
        --ignore=tests/test_sqlmodel.py \
        -v
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
