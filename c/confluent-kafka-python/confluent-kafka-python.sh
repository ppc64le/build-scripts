#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : confluent-kafka-python
# Version       : v2.10.0
# Source repo   : https://github.com/confluentinc/confluent-kafka-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="confluent-kafka-python"
PACKAGE_VERSION="${1:-v2.10.0}"
PACKAGE_URL="https://github.com/confluentinc/confluent-kafka-python"

# =============================================================================
# Artifact Declaration (runtime)
# build_info.json must also list librdkafka in build_deps for the preprocessor.
# =============================================================================
BUILD_DEPS="${BUILD_DEPS:-librdkafka:v2.10.0}"
# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
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
# CALLBACK: pre_build — source the librdkafka artifact built by librdkafka.sh
# =============================================================================
pre_build() {
    log_info "Sourcing librdkafka artifact (build l/librdkafka/librdkafka.sh first)"
    source_artifact librdkafka
    log_info "librdkafka artifact sourced: LIBRDKAFKA_PREFIX=${LIBRDKAFKA_PREFIX}"
}

# =============================================================================
# CALLBACK: pre_test — install build backend and test deps, source librdkafka artifact
# =============================================================================
pre_test() {
    log_info "Installing build backend and test dependencies into test venv"
    python -m pip install --upgrade pip "setuptools${SETUPTOOLS_VERSION-<70}" wheel
    python -m pip install avro urllib3

    log_info "Sourcing librdkafka artifact for tests"
    source_artifact librdkafka
}

# =============================================================================
# CALLBACK: custom_test_command — run tests with custom settings and deselects
# =============================================================================
custom_test_command() {
    log_info "Running pytest"
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        -k 'not test_kafkaError_unknonw_error' \
        tests/ \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

