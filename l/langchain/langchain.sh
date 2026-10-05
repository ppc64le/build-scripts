#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : langchain
# Version       : langchain==1.2.10
# Source repo   : https://github.com/langchain-ai/langchain
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="langchain"
PACKAGE_VERSION="${1:-langchain==1.2.10}"
PACKAGE_URL="https://github.com/langchain-ai/langchain"

NOARCH="true"
PYPI_VERSION="${PACKAGE_VERSION##*==}"   # strips "langchain==" → "0.3.26" / "1.2.10"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip gcc gcc-c++"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone
# =============================================================================
post_clone() {
    if [[ "$PYPI_VERSION" == 0.3.* ]]; then
        log_info "0.3.x layout: entering libs/langchain"
        cd libs/langchain
    else
        log_info "1.x layout: entering libs/langchain_v1"
        cd libs/langchain_v1
    fi
}

# =============================================================================
# CALLBACK: pre_test
# =============================================================================
pre_test() {
    log_info "Installing common test dependencies"

    # 0.3.x requires a tighter syrupy pin; 1.x accepts a wider range
    local SYRUPY_PIN="syrupy>=4.0.0,<6.0.0"
    if [[ "$PYPI_VERSION" == 0.3.* ]]; then
        SYRUPY_PIN="syrupy>=4.0.2,<5.0.0"
    fi

    python -m pip install \
        python-dotenv \
        blockbuster \
        pytest-mock \
        pytest-timeout \
        toml \
        pandas \
        freezegun \
        lark \
        pytest-asyncio \
        pytest-socket \
        "${SYRUPY_PIN}"

    if [[ "$PYPI_VERSION" == 1.* ]]; then
        log_info "Installing additional 1.x test dependencies"
        python -m pip install \
            "vcrpy>=8.0.0,<9.0.0" \
            "pytest-asyncio>=0.20.0,<2.0.0" \
            "pytest-socket>=0.7.0,<1.0.0" \
            "syrupy>=4.0.0,<6.0.0" \
            pytest-recording \
            pytest-benchmark \
            pytest-codspeed

        python -m pip install \
            "langgraph==1.0.10" \
            "langgraph-prebuilt==1.0.8" \
            "langgraph-checkpoint==4.1.1"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command
    # Skip integration tests since they require external LLM API credentials
    # (OpenAI, Anthropic, etc.) that are not available in the build environment.
    #
    # Skip test_socket_disabled because it validates pytest-socket's
    # network-blocking behavior, which is not enforced in our test environment.
# =============================================================================
custom_test_command() {
    log_info "Pinning langchain-core from local source (libs/core)"
    pushd ../core
    python -m pip install .
    popd

    log_info "Installing langchain-tests from local source (libs/standard-tests)"
    pushd ../standard-tests
    python -m pip install .
    popd

    log_info "Installing langchain-test from local source "
    pushd ../text-splitters
    python -m pip install .
    popd

    log_info "Running test..."
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        tests/unit_tests \
        -k "not integration and not test_socket_disabled"
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
