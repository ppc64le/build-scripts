#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : mongo-python-driver
# Version       : 4.13.0
# Source repo   : https://github.com/mongodb/mongo-python-driver
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - mongo-python-driver (pymongo) has optional C extensions for performance
#   - Container environment provides: gcc/g++ for C extension compilation
#   - Repository is pre-cloned with full history for version flexibility
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="mongo-python-driver"
PACKAGE_VERSION="${1:-4.13.0}"
PACKAGE_URL="https://github.com/mongodb/mongo-python-driver"

# Override the template default of setuptools<70 — pymongo 4.13.0+ requires
# setuptools>=82.0.0 for PEP 639 SPDX license string support in pyproject.toml
SETUPTOOLS_VERSION=">=82.0.0"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building mongo-python-driver
# Note: gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip openssl-devel"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv libssl-dev"
SLES_DEP_PKGS="git python3-devel python3-pip libopenssl-devel"

# =============================================================================
# CALLBACK: post_clone
# Modify pyproject.toml to exclude virtual environment directories from sdist
# This prevents AbsoluteLinkError when building source distribution
# =============================================================================
post_clone() {
    log_info "Configuring pyproject.toml to exclude virtual environments from sdist..."

    # Check if pyproject.toml exists
    if [[ ! -f "pyproject.toml" ]]; then
        log_error "pyproject.toml not found"
        return 1
    fi

    # Add exclusion for .venv-* directories to prevent AbsoluteLinkError
    # This covers both .venv-build and .venv-test directories
    # Virtual environment symlinks contain absolute paths which Python 3.9+ rejects
    if ! grep -q "\[tool.hatch.build.targets.sdist\]" pyproject.toml; then
        log_info "Adding [tool.hatch.build.targets.sdist] section to pyproject.toml"
        cat >> pyproject.toml << 'EOF'

[tool.hatch.build.targets.sdist]
exclude = [
    ".venv-*",
]
EOF
    fi

}

# =============================================================================
# CALLBACK: pre_build
# Install hatchling build backend - runs inside .venv-build
# =============================================================================
pre_build() {
    log_info "Installing hatchling build backend and plugins..."
    pip install hatchling 'hatch-requirements-txt>=0.4.1'
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests with known-failing tests deselected
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies..."
    pip install -e ".[test]" || { log_error "Failed to install test dependencies"; return 1; }

    # Use upstream requirements/test.txt when available (4.13.0+).
    # Fall back to explicit installs for older versions (e.g. 4.6.2) that do
    # not ship that file.
    if [[ -f "requirements/test.txt" ]]; then
        log_info "Installing test dependencies from requirements/test.txt..."
        pip install -r requirements/test.txt || { log_warn "Failed to install from requirements/test.txt"; }
    else
        log_info "requirements/test.txt not found, installing test dependencies manually..."
        pip install 'pytest-asyncio>=0.21.0' || { log_warn "Failed to install pytest-asyncio"; }
        pip install --upgrade "pytest>=7.0" || { log_warn "Failed to upgrade pytest"; }
    fi
    pip uninstall -y pytest-cov pytest-xdist 2>/dev/null

    log_info "Running pytest with platform-specific test deselections..."
    
    # Skip integration tests that require external MongoDB infrastructure:
    # - test/atlas/: Requires MongoDB Atlas connection
    # - test/auth_aws/: Requires AWS authentication setup
    # - test/auth_oidc/: Requires OIDC authentication setup
    # - test/mockupdb/: Requires MockupDB library
    # - test/ocsp/: Requires OCSP certificate validation setup
    # - test/performance/: Performance benchmarks requiring MongoDB
    #
    # Skip OIDC auth tests requiring live MongoDB + OIDC provider:
    # - test_auth_oidc.py: Requires MONGODB_URI_SINGLE env var and OIDC-enabled MongoDB server
    #
    # Skip encryption tests requiring KMS providers:
    # - test_encryption.py: Requires AWS KMS, Azure Key Vault, GCP KMS, or KMIP providers
    #   These tests need external key management services that are not available in build environments
    #
    # Skip data lake tests:
    # - test_data_lake.py: Requires MongoDB Atlas Data Lake connection
    #
    # Skip search index tests:
    # - test_index_management.py (SearchIndex tests): Require MongoDB Atlas Search environment variables
    #
    # Skip container metadata tests:
    # - test_container_metadata: expects specific container runtime metadata
    # - test_metadata: mismatched runtime/environment expectations

    pytest \
        -o "addopts=" \
        --ignore=test/atlas \
        --ignore=test/auth_aws \
        --ignore=test/auth_oidc \
        --ignore=test/mockupdb \
        --ignore=test/ocsp \
        --ignore=test/performance \
        --ignore=test/test_auth_oidc.py \
        --ignore=test/asynchronous/test_auth_oidc.py \
        --ignore=test/test_data_lake.py \
        --ignore=test/asynchronous/test_data_lake.py \
        --ignore=test/test_encryption.py \
        --ignore=test/asynchronous/test_encryption.py \
        -k "not test_container_metadata and not test_metadata and not TestSearchIndex" \
        -W ignore::pytest.PytestDeprecationWarning \
        --disable-warnings
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
