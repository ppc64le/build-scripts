#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : duckdb
# Version       : v1.5.4
# Source repo   : https://github.com/duckdb/duckdb-python
# Tested on     : UBI:9.6
# Language      : Python, C++
# Script License: Apache License, Version 2 or later
# Maintainer    : Jason Cho <jason.cho2@ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="duckdb"
PACKAGE_VERSION="${1:-v1.5.4}"
PACKAGE_URL="https://github.com/duckdb/duckdb-python"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake git libomp-devel make ninja-build python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — update submodules and read setuptools requirement
# =============================================================================
post_clone() {
    log_info "Updating git submodules..."
    git submodule update --init --recursive

    log_info "Reading setuptools version requirement from pyproject.toml"
    if [[ -f "pyproject.toml" ]]; then
        setuptools_req="$(grep -o '"setuptools[><=^~][^"]*"' pyproject.toml | head -1 | tr -d '"')"
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
# CALLBACK: pre_build — configure build environment and install dependencies
# =============================================================================
pre_build() {
    log_info "Setting build environment variables..."
    export DUCKDB_BUILD_PYTHON=1
    export DUCKDB_BUILD_STATIC=1
    export CMAKE_BUILD_PARALLEL_LEVEL="${CMAKE_BUILD_PARALLEL_LEVEL:-4}"

    log_info "Installing build dependencies..."
    python -m pip install setuptools wheel cmake ninja "pybind11[global]" scikit-build-core setuptools_scm
}

# =============================================================================
# CALLBACK: pre_test — mirror build dependencies into test virtual environment
# =============================================================================
pre_test() {
    log_info "Installing build backend and test dependencies..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cmake ninja "pybind11[global]" scikit-build-core setuptools_scm pytest
}

# =============================================================================
# CALLBACK: custom_test_command — verify DuckDB installation and basic SQL execution
# =============================================================================
custom_test_command() {
    log_info "Running DuckDB runtime smoke tests..."
    python - <<EOF
import duckdb

# Ensure correct package loaded
assert hasattr(duckdb, "connect"), "duckdb.connect missing"

con = duckdb.connect()

# 1 Basic SQL test
assert con.execute("select 42").fetchall() == [(42,)]

# 2 Version check (SQL side)
version_sql = con.execute("select version()").fetchone()[0]
assert version_sql.startswith("${PACKAGE_VERSION}")

# 3 Python package version check
assert duckdb.__version__ == "${PACKAGE_VERSION#v}"

print("All DuckDB runtime tests passed.")
EOF
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
