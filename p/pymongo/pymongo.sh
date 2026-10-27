#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pymongo
# Version       : 4.17.0
# Source repo   : https://github.com/mongodb/mongo-python-driver
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pymongo"
PACKAGE_VERSION="${1:-4.17.0}"
PACKAGE_URL="https://github.com/mongodb/mongo-python-driver"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip openssl-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone
# Two patches applied to pyproject.toml after checkout:
#
# 1. Append [tool.hatch.build.targets.sdist] exclude for venv dirs.
#    Python 3.14+ tarfile rejects absolute symlinks (e.g. .venv-build/bin/python3
#    -> /usr/bin/python3) with AbsoluteLinkError when extracting the sdist.
#
# 2. Export SETUPTOOLS_VERSION="" to lift the template's default <70 cap.
#    pymongo 4.17.0 uses license = "Apache-2.0" (SPDX string, PEP 639) which
#    setuptools <74 rejects as invalid pyproject.toml config. Latest setuptools
#    supports both the old {file/text} form (4.13.0) and the SPDX string form.
# =============================================================================
post_clone() {
    log_info "Patching pyproject.toml to exclude venv dirs from sdist..."
    cat >> pyproject.toml << 'EOF'

[tool.hatch.build.targets.sdist]
exclude = [
    ".venv-build",
    ".venv-test",
]
EOF
    log_info "pyproject.toml patched successfully"

    # Lift the template's default setuptools<70 cap so that setuptools>=74 is
    # installed — required for pymongo 4.17.0's SPDX license string format
    export SETUPTOOLS_VERSION=""
    log_info "SETUPTOOLS_VERSION set to '' (latest) for SPDX license compatibility"
}

# =============================================================================
# CALLBACK: pre_build
# Install hatchling and hatch-requirements-txt before python -m build runs.
# pymongo's pyproject.toml declares:
#   build-backend = "hatchling.build"
#   requires = ["hatchling>1.24", "setuptools>=65.0", "hatch-requirements-txt>=0.4.1"]
# The template builds with --no-isolation so these must be present in the venv.
# =============================================================================
pre_build() {
    log_info "Installing hatchling build backend dependencies..."
    python -m pip install "hatchling>1.24" "hatch-requirements-txt>=0.4.1"
}

# =============================================================================
# CALLBACK: pre_test
# Upgrade pip/setuptools/wheel in the test venv (C-extension package).
# Install pytest-asyncio so that asyncio_default_fixture_loop_scope (declared
# in pyproject.toml [tool.pytest.ini_options]) is a recognised config option
# and does not trigger PytestUnknownMarkWarning treated as error.
# =============================================================================
pre_test() {
    log_info "Installing pymongo test dependencies..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "hatchling>1.24" "hatch-requirements-txt>=0.4.1"
    python -m pip install "pytest-asyncio>=0.21"
}

# =============================================================================
# CALLBACK: custom_test_command
# Run only pure unit tests that require no live MongoDB connection.
# The conftest.py package-scoped fixture calls setup()/teardown() which checks
# gc.garbage and raises AssertionError when MongoDB connection objects are left
# behind from connection attempts against a non-existent server.  Targeting
# individual unit-test files bypasses the conftest fixture entirely.
#
# -o "addopts=" clears addopts from pytest.ini / pyproject.toml (--junitxml,
#   --strict-config, -m default or default_async) so we control the run.
# -o "filterwarnings=" clears pyproject.toml filterwarnings = ["error", ...]
#   (present in 4.17.0+) which turns the pytest-asyncio PytestDeprecationWarning
#   (from conftest.py overriding event_loop_policy) into an error that aborts
#   the entire session fixture, causing all tests to show as ERROR.
# -o "asyncio_mode=auto" satisfies asyncio_default_fixture_loop_scope (4.17.0+)
#   without the deprecated event_loop_policy fixture override.
#
# test/test_bson_binary_vector.py was added after 4.6.2; guard with -e check
# so older versions don't abort with "file or directory not found".
#
# Files excluded: anything that subclasses IntegrationTest or uses
# @client_context.require_connection (needs a live mongod).
# =============================================================================
custom_test_command() {
    log_info "Running pymongo unit tests (no live MongoDB required)..."
    # test_bson_binary_vector.py was introduced after 4.6.x
    local extra_tests=""
    [[ -f test/test_bson_binary_vector.py ]] && extra_tests="test/test_bson_binary_vector.py"
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        -o "filterwarnings=" \
        -o "asyncio_mode=auto" \
        --disable-warnings \
        test/test_bson.py \
        ${extra_tests} \
        test/test_code.py \
        test/test_dbref.py \
        test/test_decimal128.py \
        test/test_default_exports.py \
        test/test_errors.py \
        test/test_json_util.py \
        test/test_objectid.py \
        test/test_results.py \
        test/test_saslprep.py \
        test/test_server_description.py \
        test/test_server_selection_rtt.py \
        test/test_son.py \
        test/test_timestamp.py \
        test/test_topology.py \
        test/test_uri_parser.py \
        test/test_uri_spec.py \
        test/test_write_concern.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
