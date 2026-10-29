#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cython-blis
# Version       : release-v1.3.3
# Source repo   : https://github.com/explosion/cython-blis
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cython-blis"
PACKAGE_VERSION="${1:-release-v1.3.3}"
PACKAGE_URL="https://github.com/explosion/cython-blis"

# =============================================================================
# Artifact dependencies
# =============================================================================
BUILD_DEPS="numpy"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_clone — normalize PACKAGE_VERSION to the git tag format used
#           by the upstream repository.
#
#           Deep Scan may provide a bare version such as "1.3.3", while the
#           upstream repository uses tags such as "release-v1.3.3".
# =============================================================================
pre_clone() {
    local bare="${PACKAGE_VERSION#release-v}"
    bare="${bare#release-}"
    bare="${bare#v}"

    PACKAGE_VERSION="release-v${bare}"

    log_info "Resolved PACKAGE_VERSION → ${PACKAGE_VERSION}"
}

# =============================================================================
# CALLBACK: post_clone — read the setuptools requirement from pyproject.toml.
#
#           pyproject.toml is available only after the repository has been
#           cloned, so this logic belongs in post_clone rather than pre_clone.
# =============================================================================
post_clone() {
    log_info "Reading setuptools version from pyproject.toml"

    setuptools_req="$(grep -o '"setuptools[^"]*"' pyproject.toml | head -1 | tr -d '"')"
    SETUPTOOLS_VERSION="${setuptools_req#setuptools}"
    SETUPTOOLS_VERSION="${SETUPTOOLS_VERSION//[[:space:]]/}"

    if [[ -z "${SETUPTOOLS_VERSION}" ]]; then
        SETUPTOOLS_VERSION="<82"
        log_info "No setuptools pin in pyproject.toml — using fallback SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    else
        log_info "Using SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}' from pyproject.toml"
    fi
}

# =============================================================================
# CALLBACK: pre_build — set compiler/architecture environment variables and
#           install Cython.
#
#           NumPy is provided through BUILD_DEPS and its environment setup.
#           BLIS_ARCH and compiler variables must be exported before the build.
# =============================================================================
pre_build() {
    log_info "Exporting compiler environment and BLIS architecture for ppc64le Power9"

    export CC=/usr/bin/gcc
    export CXX=/usr/bin/g++
    export BLIS_ARCH=power9

    log_info "Installing build dependency: cython"

    python -m pip install "cython>=3.0,<4.0"
}

# =============================================================================
# CALLBACK: pre_test — install the build backend and test dependencies into
#           the isolated test environment.
# =============================================================================
pre_test() {
    log_info "Exporting compiler environment and BLIS architecture for ppc64le Power9"

    export CC=/usr/bin/gcc
    export CXX=/usr/bin/g++
    export BLIS_ARCH=power9

    log_info "Installing build backend and test dependencies into test venv"

    python -m pip install --upgrade pip "setuptools${SETUPTOOLS_VERSION}" wheel
    python -m pip install "cython>=3.0,<4.0"
    python -m pip install pytest hypothesis
}

# =============================================================================
# CALLBACK: custom_test_command — run tests against the installed package.
#
#           --pyargs resolves tests from the installed package and
#           --import-mode=importlib avoids source-tree shadowing of the
#           compiled blis modules.
# =============================================================================
custom_test_command() {
    log_info "Running blis tests against installed package (--pyargs avoids source-tree shadowing)"

    python -I -m pytest --import-mode=importlib --pyargs blis
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
