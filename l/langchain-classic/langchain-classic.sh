#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : langchain-classic
# Version       : langchain-classic==1.0.1
# Source repo   : https://github.com/langchain-ai/langchain
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Sanket-Kumbhar <Sanket.Kumbhar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="langchain-classic"
PACKAGE_VERSION="${1:-langchain-classic==1.0.1}"
PACKAGE_URL="https://github.com/langchain-ai/langchain"

NOARCH="true"
PYPI_VERSION="${PACKAGE_VERSION##*==}"   # strips "langchain-classic==" → "1.0.1"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip gcc gcc-c++"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — enter the libs/langchain_v1 sub-package
# =============================================================================
post_clone() {
    log_info "1.x layout: entering libs/langchain_v1"
    cd libs/langchain_v1
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing common test dependencies"

    python -m pip install \
        python-dotenv \
        blockbuster \
        pytest-mock \
        pytest-timeout \
        toml \
        freezegun \
        lark \
        greenlet \
        pytest-recording \
        pytest-benchmark \
        pytest-codspeed \
        "vcrpy>=8.0.0,<9.0.0" \
        "pytest-asyncio>=0.20.0,<2.0.0" \
        "pytest-socket>=0.7.0,<1.0.0" \
        "syrupy>=4.0.0,<6.0.0" \
        "langgraph==1.0.10" \
        "langgraph-prebuilt==1.0.8" \
        "langgraph-checkpoint==4.1.1"
}

# =============================================================================
# CALLBACK: custom_test_command — install local core packages and run unit tests
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

    log_info "Installing langchain-text-splitters from local source (libs/text-splitters)"
    pushd ../text-splitters
    python -m pip install .
    popd

    log_info "Running test..."
    # Skip integration tests since they require external LLM API credentials
    # (OpenAI, Anthropic, etc.) that are not available in the build environment.
    #
    # Skip test_socket_disabled because it validates pytest-socket's
    # network-blocking behavior, which is not enforced in our test environment.
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        tests/unit_tests \
        -k "not integration and not test_socket_disabled"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
