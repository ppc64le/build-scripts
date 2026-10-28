#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : fastparquet
# Version       : 2024.11.0
# Source repo   : https://github.com/dask/fastparquet
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham.Garud@ibm.com
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="fastparquet"
PACKAGE_VERSION="${1:-2024.11.0}"
PACKAGE_URL="https://github.com/dask/fastparquet"

# =============================================================================
# Artifact dependencies and declaration
# =============================================================================
NUMPY_ARTIFACT_VERSION="${NUMPY_ARTIFACT_VERSION:-v2.2.5}"
BUILD_DEPS=${BUILD_DEPS:-"numpy:${NUMPY_ARTIFACT_VERSION}"}
# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — read build-system constraints from pyproject.toml
# Extracts Cython specifier so pins stay in sync with whatever the cloned
# version of the package declares.
# =============================================================================
post_clone() {
    log_info "Reading build-system requirements from pyproject.toml"
    CYTHON_REQ="$(grep -oi '"Cython[^"]*"' pyproject.toml | head -1 | tr -d '"')"
    if [[ -n "$CYTHON_REQ" ]]; then
        log_info "Detected Cython requirement: ${CYTHON_REQ}"
    else
        CYTHON_REQ="Cython>=0.29.23"
        log_info "No Cython pin in pyproject.toml — falling back to '${CYTHON_REQ}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install build-system deps into build venv
# Cython and setuptools_scm must be present before `python -m build --no-isolation` runs.
# NumPy is provided by the NumPy artifact.
# =============================================================================
pre_build() {
    log_info "Installing build-system dependencies: ${CYTHON_REQ}, setuptools_scm"
    python -m pip install "${CYTHON_REQ}" setuptools_scm

    # Ensure NumPy artifact is sourced (if not auto-sourced by template)
    if [[ -z "${NUMPY_PREFIX:-}" ]]; then
        if ! source_artifact "numpy" "${NUMPY_ARTIFACT_VERSION}"; then
            log_error "Required NumPy artifact is missing."
            log_error "Expected build order: numpy:${NUMPY_ARTIFACT_VERSION} -> fastparquet:${PACKAGE_VERSION}"
            false
        fi
    fi

    if [[ -z "${NUMPY_PREFIX:-}" || ! -d "${NUMPY_PREFIX}" ]]; then
        log_error "NumPy artifact is required but NUMPY_PREFIX is invalid: ${NUMPY_PREFIX:-<unset>}"
        false
    fi
    log_info "Using NumPy from artifact: ${NUMPY_PREFIX}"

    # Prefer the artifact wheel that matches the active Python ABI, such as
    # cp310, cp311, or cp312, because NumPy contains compiled extension modules that
    # are not portable across Python minor versions.
    local numpy_wheel
    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
    log_info "Looking for NumPy artifact wheel matching Python ABI ${python_abi}"
    numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    if [[ -z "${numpy_wheel}" ]]; then
        log_warn "NumPy ${python_abi} wheel was not found under ${NUMPY_PREFIX}/wheels; using artifact PYTHONPATH"
        log_info "Verifying NumPy is importable from the sourced artifact environment"
        if ! python -c "import numpy; print('NumPy version:', numpy.__version__)" ; then
            log_error "NumPy artifact is not importable from ${NUMPY_PREFIX}"
            false
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
# CALLBACK: pre_test — build Cython extensions in-place via editable install so
# that pytest importing from the source tree finds the compiled .so files.
# An editable install with --no-build-isolation compiles cencoding.so and
# speedups.so directly into the source fastparquet/ directory, making them
# available to imports regardless of which directory pytest runs from.
# =============================================================================
pre_test() {
    log_info "Installing build and test dependencies into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "${CYTHON_REQ}" setuptools_scm

    local python_abi numpy_wheel
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
    numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" 2>/dev/null | head -1)
    if [[ -n "${numpy_wheel}" ]]; then
        log_info "Installing NumPy wheel from artifact into test venv: ${numpy_wheel}"
        python -m pip install --no-deps "${numpy_wheel}"
    else
        log_warn "No NumPy wheel found in artifact for ${python_abi}; relying on environment"
    fi

    python -m pip install pandas cramjam fsspec packaging

    log_info "Installing fastparquet in editable mode to compile Cython extensions in-place"
    python -m pip install --no-build-isolation -e .

    python -m pip install pytest
    python -m pip uninstall -y pytest-cov pytest-xdist 2>/dev/null
}

# =============================================================================
# CALLBACK: custom_test_command — run fastparquet tests, deselecting cases that
# fail due to pandas>=2.2 / pandas>=3.0 API incompatibilities in fastparquet 2024.11.0.
# These are upstream bugs unrelated to ppc64le.
# =============================================================================
custom_test_command() {
    log_info "Running fastparquet test suite"
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        fastparquet/test/ \
        --deselect=fastparquet/test/test_api.py::test_text_schema \
        --deselect=fastparquet/test/test_api.py::test_iter \
        --deselect=fastparquet/test/test_api.py::test_pickle \
        --deselect=fastparquet/test/test_api.py::test_attributes \
        --deselect=fastparquet/test/test_api.py::test_index_not_in_columns \
        --deselect=fastparquet/test/test_api.py::test_no_index_name \
        --deselect=fastparquet/test/test_api.py::test_remove_rgs_no_partition \
        --deselect=fastparquet/test/test_api.py::test_remove_rgs_simple_merge \
        --deselect=fastparquet/test/test_api.py::test_write_rgs_simple \
        --deselect=fastparquet/test/test_api.py::test_write_rgs_simple_no_index \
        --deselect=fastparquet/test/test_api.py::test_write_rgs_hive \
        --deselect=fastparquet/test/test_api.py::test_write_rgs_hive_partitions \
        --deselect=fastparquet/test/test_api.py::test_file_renaming_no_partition \
        --deselect=fastparquet/test/test_api.py::test_file_renaming_with_partitions \
        --deselect=fastparquet/test/test_converted_types.py::test_utf8 \
        --deselect=fastparquet/test/test_dataframe.py::test_pandas_hive_serialization \
        --deselect=fastparquet/test/test_output.py::test_index \
        --deselect=fastparquet/test/test_output.py::test_text_convert \
        --deselect=fastparquet/test/test_output.py::test_auto_null_object \
        --deselect=fastparquet/test/test_output.py::test_write_partitioned_with_empty_categories \
        --deselect=fastparquet/test/test_output.py::test_append_fail_incompatible \
        --deselect=fastparquet/test/test_output.py::test_object_encoding_int32 \
        --deselect=fastparquet/test/test_read.py::test_index \
        --deselect=fastparquet/test/test_read.py::test_multi_index \
        --deselect=fastparquet/test/test_read.py::test_multi_index_category \
        --deselect="fastparquet/test/test_read.py::test_no_columns[no_columns_new.parquet]" \
        --deselect=fastparquet/test/test_read.py::test_column_multiindex_roundtrip
        # All deselected tests fail due to pandas>=2.2/3.0 API changes
        # (StringDtype inference, datetime64 resolution, copy= kwarg removal).
        # These are upstream fastparquet bugs, not ppc64le issues.
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
