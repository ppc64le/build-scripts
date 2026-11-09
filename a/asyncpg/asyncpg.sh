#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : asyncpg
# Version       : v0.31.0
# Source repo   : https://github.com/MagicStack/asyncpg
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Ethan Choe <ethanchoe@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="asyncpg"
PACKAGE_VERSION="${1:-v0.31.0}"
PACKAGE_URL="https://github.com/MagicStack/asyncpg"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone
# =============================================================================
post_clone() {
    log_info "Reading setuptools version requirement from pyproject.toml"
    if [[ -f "pyproject.toml" ]]; then
        setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
        if [[ -n "$setuptools_req" ]]; then
            SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
            SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"
            # setup.py imports pkg_resources, which was removed in setuptools 82
            SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION},<82"
            log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
        else
            log_info "No setuptools pin found in pyproject.toml — using template default"
        fi
    fi

    log_info "Patching pyproject.toml for PEP 621 license compliance"
    if grep -q '^license = "Apache-2.0"' pyproject.toml 2>/dev/null; then
        sed -i 's/^license = "Apache-2.0"/license = {text = "Apache-2.0"}/' pyproject.toml
    fi

    log_info "Removing license-files from pyproject.toml"
    sed -i '/^license-files/d' pyproject.toml
}

# =============================================================================
# CALLBACK: pre_build — install Cython build dependency
# =============================================================================
pre_build() {
    log_info "Installing Cython build dependency"
    python -m pip install "cython>=3.2.1,<4.0.0"
}

# =============================================================================
# CALLBACK: custom_test_command
# =============================================================================
custom_test_command() {
    log_info "Running version check"
    if ! (cd .. && python -c "import asyncpg; print('asyncpg.__file__:', asyncpg.__file__); print('version:', asyncpg.__version__)"); then
        return 1
    fi

    log_info "Validating C extensions and API surface"
    if ! (cd .. && python - <<'EOF'
import asyncpg

# Exception hierarchy — exercises the compiled asyncpg.exceptions C extension
assert issubclass(asyncpg.PostgresError,            Exception)
assert issubclass(asyncpg.UniqueViolationError,     asyncpg.PostgresError)
assert issubclass(asyncpg.UndefinedTableError,      asyncpg.PostgresError)
assert issubclass(asyncpg.ForeignKeyViolationError, asyncpg.PostgresError)
print("exception hierarchy: OK")

# Public API presence
for name in ("connect", "create_pool", "Connection", "Pool",
             "Record", "PostgresError"):
    assert hasattr(asyncpg, name), f"Missing asyncpg.{name}"
print("public API surface: OK")

# Record is a compiled C type — verify it is a type (not a plain Python class)
assert isinstance(asyncpg.Record, type), "asyncpg.Record is not a type"
assert asyncpg.Record.__name__ == "Record"
print("Record C extension: OK")

# pgproto — confirm the compiled pgproto extension loaded and exposes its types
import asyncpg.pgproto.pgproto as _pgproto
for name in ("WriteBuffer", "ReadBuffer", "UUID"):
    assert hasattr(_pgproto, name), f"Missing asyncpg.pgproto.pgproto.{name}"
print("pgproto C extension: OK")
EOF
    ); then
        return 1
    fi

    log_info "All C extension validation checks passed"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
