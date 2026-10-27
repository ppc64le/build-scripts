#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : SQLAlchemy
# Version       : rel_2_0_50
# Source repo   : https://github.com/sqlalchemy/sqlalchemy
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : vivek sharma <vivek.sharma20@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="sqlalchemy"
PACKAGE_VERSION="${1:-rel_2_0_50}"
PACKAGE_URL="https://github.com/sqlalchemy/sqlalchemy"

RH_DEP_PKGS="git openssl-devel bzip2-devel libffi-devel zlib-devel sqlite-devel python3-devel python3-pip"
DEB_DEP_PKGS="git libssl-dev libbz2-dev libffi-dev zlib1g-dev libsqlite3-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git libopenssl-devel libbz2-devel libffi-devel zlib-devel sqlite3-devel python3-devel python3-pip"

# =============================================================================
# CALLBACK: post_clone — remove .dev0 suffix from wheel name in setup.cfg
# =============================================================================
post_clone() {
    log_info "Patching setup.cfg to remove .dev0 suffix from wheel name..."
    if [[ -f "setup.cfg" ]]; then
        sed -i '/^\[egg_info\]/,/\[/{s/^\(tag_build = dev\)/# \1/}' setup.cfg
    fi
}

# =============================================================================
# CALLBACK: pre_build — install Cython and greenlet for C extension support
# =============================================================================
pre_build() {
    log_info "Installing Cython and greenlet for SQLAlchemy C extensions..."
    python -m pip install cython greenlet
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps and install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing build backend dependencies in test venv..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cython greenlet

    log_info "Installing SQLAlchemy test extras..."
    python -m pip install ".[testing]"

    log_info "Removing pytest plugins that cause entrypoint import crashes..."
    python -m pip uninstall -y pytest-cov pytest-xdist pytest-codspeed
}

# =============================================================================
# CALLBACK: custom_test_command — run functional tests; ignore mypy-dependent
#           test trees and deselect SQLite RETURNING tests unsupported on 3.34.x
# Ignored:
#   test/typing/        — invokes 'from mypy import api' at collection time;
#                         mypy is a static analysis tool used only in upstream
#                         typing CI, not a functional correctness check on ppc64le
#   test/ext/mypy/      — same reason; SQLAlchemy mypy plugin tests require mypy
# Deselected:
#   test_on_conflict.py::*::test_on_conflict_do_update_bindparam[*-use_returning]
#                       — SQLite RETURNING clause requires SQLite >= 3.35.0;
#                         ppc64le CI runs SQLite 3.34.1 which does not support it
# =============================================================================
custom_test_command() {
    log_info "Running SQLAlchemy tests (excluding mypy and unsupported SQLite tests)..."
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --ignore=test/typing \
        --ignore=test/ext/mypy \
        --deselect "test/dialect/sqlite/test_on_conflict.py::OnConflictTest_sqlite+pysqlite_3_34_1::test_on_conflict_do_update_bindparam[differentname-use_returning]" \
        --deselect "test/dialect/sqlite/test_on_conflict.py::OnConflictTest_sqlite+pysqlite_3_34_1::test_on_conflict_do_update_bindparam[fixed-use_returning]" \
        --deselect "test/dialect/sqlite/test_on_conflict.py::OnConflictTest_sqlite+pysqlite_3_34_1::test_on_conflict_do_update_bindparam[samename-use_returning]"
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
