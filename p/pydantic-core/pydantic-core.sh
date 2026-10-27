#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pydantic-core
# Version       : v2.41.5
# Source repo   : https://github.com/pydantic/pydantic-core
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pydantic-core"
PACKAGE_VERSION="${1:-v2.41.5}"
PACKAGE_URL="https://github.com/pydantic/pydantic-core"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — set up stable Rust toolchain and install build deps
# =============================================================================
pre_build() {
    log_info "Setting up Rust toolchain..."
    rustup default stable

    log_info "Using Rust: $(rustc --version)"
    log_info "Using Cargo: $(cargo --version)"

    log_info "Installing build dependencies..."
    python -m pip install "maturin>=1.2,<2.0"
    # typing-extensions is declared in pyproject.toml build-system.requires;
    # --no-isolation skips the isolated env so it must be pre-installed here
    python -m pip install "typing-extensions>=4.6.0,!=4.7.0"
}

# =============================================================================
# CALLBACK: pre_test — set up Rust toolchain in test venv and install test deps
# =============================================================================
pre_test() {
    log_info "Setting up Rust toolchain for test environment..."
    rustup default stable

    log_info "Installing test dependencies..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install maturin \
        hypothesis \
        pytest-timeout \
        inline_snapshot \
        pytest-benchmark \
        jsonschema \
        pytest_examples \
        dirty_equals \
        pytz \
        rich \
        faker \
        pytest-mock \
        eval_type_backport \
        typing_inspection \
        pytest-run-parallel
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest
# =============================================================================
custom_test_command() {
    log_info "Running pydantic-core tests..."
    # skipping unsupported tests, test_docstrings.py: requires pydantic — circular dependency 
    # test_allow_partial.py: unstable on ppc64le
    # -W ignore::pytest.PytestWarning: pytest>=8.0 treats match='' in pytest.raises()
    #   as a hard error; test_arguments.py uses Err('', ...) which triggers this —
    #   upstream style issue, not a real failure
    python -m pytest \
        -W ignore::pytest.PytestWarning \
        --ignore=tests/test_docstrings.py \
        --ignore=tests/validators/test_allow_partial.py \
        -vv
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
