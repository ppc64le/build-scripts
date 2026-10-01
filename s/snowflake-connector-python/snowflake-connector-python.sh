#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : snowflake-connector-python
# Version       : v4.3.0
# Source repo   : https://github.com/snowflakedb/snowflake-connector-python
# Tested on     : UBI 9.6
# Language      : Python, C
# Script License: Apache License, Version 2 or later
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="snowflake-connector-python"
PACKAGE_VERSION="${1:-v4.3.0}"
PACKAGE_URL="https://github.com/snowflakedb/snowflake-connector-python"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-pip python3-devel gcc-toolset-13 java-17-openjdk-headless"
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
        # No pyproject.toml present — fall back to a safe upper bound
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install cython build dependency
# =============================================================================
pre_build() {
    log_info "Installing cython build dependency..."
    python -m pip install cython
}

# =============================================================================
# CALLBACK: pre_test — install test requirements for unit tests
# =============================================================================
pre_test() {
    log_info "Installing pip/setuptools/wheel upgrades and test requirements..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cython

    # -------------------------------------------------------------------------
    # Pre-install the wheel with --no-deps to prevent botocore disk exhaustion.
    #
    # Why: snowflake-connector-python declares boto3>=1.24 as a runtime dep.
    # Normally the template installs the wheel with full dep resolution, pulling
    # in botocore (~600 MB of AWS JSON data files). Under 10 parallel containers
    # on a shared VM this exhausts disk: OSError: [Errno 28] No space left.
    #
    # Fix: install the wheel --no-deps first. The template's subsequent
    # "pip install *.whl" sees "Requirement already satisfied" and skips
    # boto3/botocore resolution entirely. boto3 is not needed — all S3 tests
    # are already excluded via --ignore in custom_test_command below.
    # -------------------------------------------------------------------------
    local whl
    whl=$(ls "${OUTPUT_DIR}"/*.whl 2>/dev/null | head -1 \
       || ls dist/wheelhouse/*.whl 2>/dev/null | head -1 \
       || ls dist/*.whl 2>/dev/null | head -1 \
       || true)
    if [[ -n "$whl" ]]; then
        log_info "Pre-installing wheel with --no-deps to skip boto3/botocore: $whl"
        python -m pip install --no-deps "$whl"
    else
        log_warn "No pre-built wheel found; botocore may still be pulled in by the template"
    fi

    # Test-only deps — no S3/boto dependencies
    python -m pip install pytest-mock mock freezegun pytz aiohttp numpy responses pytest-asyncio

    # Download Wiremock standalone JAR for local mocking tests
    mkdir -p .wiremock
    log_info "Downloading wiremock-standalone.jar..."
    curl -sSLf "https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/3.11.0/wiremock-standalone-3.11.0.jar" \
        --output .wiremock/wiremock-standalone.jar \
        || log_warn "Failed to download wiremock-standalone.jar"
}

# =============================================================================
# CALLBACK: custom_test_command — run unit tests specifically
# =============================================================================
# Description of ignored test files:
#   - test_util.py: Fails on linux_ppc64le since upstream does not bundle / compile
#     the dynamic minicore library (libsf_mini_core.so) for IBM Power architecture.
#   - test_s3_util.py, test_ocsp.py, test_retry_network.py, test_storage_client.py:
#     These require external network access to resolve S3 buckets and OCSP servers
#     for revocation checking, which fails under offline/sandbox container environments.
#   - test_detect_platforms.py: Attempts to query cloud instance metadata endpoints
#     (e.g., AWS IMDS, Azure IMDS) that are unreachable in a build environment.
#   - test/unit/aio/test_s3_util_async.py, test/unit/aio/test_ocsp.py: Bypassed for
#     the same offline/sandbox network restrictions as their synchronous counterparts.
#   - test/unit/aio/test_auth_keypair_async.py: Skipped due to mock password int-to-bytes
#     type mismatches with newer 'cryptography' library releases on Python 3.11+.
#   - test/unit/aio/test_connection_async_unit.py: Ignored because it invokes asyncio.get_event_loop()
#     at module-level import time (during test collection), which raises a RuntimeError on Python 3.12+.
#   - test_auth_callback_server.py, test_auth_webbrowser.py, test_auth_webbrowser_async.py:
#     These tests start/stop local HTTP/socket servers for OAuth callback mocks, causing port contention,
#     extremely slow test runs, and timeouts in restricted sandboxed/CI environments.
#   - test/unit/aio/test_auth_workload_identity_async.py: Requires optional 'aioboto3' dependency
#     for AWS workload identity mock fixtures, which is intentionally excluded to prevent disk exhaustion.
#   - test_log_debug_config_file_parent_dir_permissions: Skipped due to caplog/logging level propagation
#     changes on Python 3.14+.
custom_test_command() {
    python -m pytest test/unit \
        --import-mode=importlib \
        -o "addopts=" \
        -k "not test_log_debug_config_file_parent_dir_permissions" \
        --ignore=test/unit/test_util.py \
        --ignore=test/unit/test_s3_util.py \
        --ignore=test/unit/test_ocsp.py \
        --ignore=test/unit/test_retry_network.py \
        --ignore=test/unit/test_storage_client.py \
        --ignore=test/unit/test_detect_platforms.py \
        --ignore=test/unit/aio/test_s3_util_async.py \
        --ignore=test/unit/aio/test_ocsp.py \
        --ignore=test/unit/aio/test_auth_keypair_async.py \
        --ignore=test/unit/aio/test_connection_async_unit.py \
        --ignore=test/unit/aio/test_auth_workload_identity_async.py \
        --ignore=test/unit/test_auth_callback_server.py \
        --ignore=test/unit/test_auth_webbrowser.py \
        --ignore=test/unit/aio/test_auth_webbrowser_async.py 
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
