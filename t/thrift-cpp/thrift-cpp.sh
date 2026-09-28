#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : thrift-cpp
# Version       : 0.21.0
# Source repo   : https://github.com/apache/thrift
# Tested on     : UBI:9.6
# Language      : C++ / Python Wheel
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="thrift-cpp"
PACKAGE_VERSION="${1:-0.21.0}"
PACKAGE_URL="https://github.com/apache/thrift"
PYPI_NAME="thriftcpp"

# =============================================================================
# Artifact Declaration (depends on boost)
# =============================================================================
BUILD_DEPS="${BUILD_DEPS:-boost}"

# =============================================================================
# REQUIRED: Dependencies
# Note: bison and flex are provided by the base container image
# =============================================================================
RH_DEP_PKGS="cmake git libevent-devel libtool make openssl-devel zlib-devel python3 python3-devel python3-pip"
DEB_DEP_PKGS="cmake git libevent-dev libtool make libssl-dev zlib1g-dev python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="cmake git libevent-devel libtool make libopenssl-devel zlib-devel python3 python3-devel python3-pip"

# =============================================================================
# CALLBACK: custom_install
# Compiles thrift C++ library and prepares python package directory structure
# =============================================================================
custom_install() {
    local SOURCE_DIR
    SOURCE_DIR="$(pwd)"
    local PREFIX_DIR="${SOURCE_DIR}/prefix"
    mkdir -p "${PREFIX_DIR}"

    log_info "Bootstrapping Thrift build system..."
    ./bootstrap.sh

    log_info "Configuring Thrift C++ build..."
    ./configure --prefix="${PREFIX_DIR}" \
        --with-boost="${BOOST_PREFIX}" \
        --with-zlib=/usr \
        --with-libevent=/usr \
        --with-openssl=/usr \
        --with-python=no \
        --with-py3=no \
        --with-ruby=no \
        --with-java=no \
        --with-kotlin=no \
        --with-erlang=no \
        --with-nodejs=no \
        --with-c_glib=no \
        --with-haxe=no \
        --with-rs=no \
        --with-cpp=yes \
        --enable-tests=no \
        --enable-tutorial=no

    log_info "Compiling and installing Thrift C++ library..."
    make -j"$(nproc)"
    make install

    # Export LD_LIBRARY_PATH (including boost prefix) so wheel tools can resolve dependencies
    export LD_LIBRARY_PATH="${PREFIX_DIR}/lib:${BOOST_PREFIX}/lib:${LD_LIBRARY_PATH:-}"

    # Prepare python packaging layout
    log_info "Preparing thriftcpp python packaging layout..."
    mkdir -p local/thriftcpp
    touch local/thriftcpp/__init__.py
    cp -r "${PREFIX_DIR}"/* local/thriftcpp/

    # Clean version string to make it PEP-440 compliant
    local CLEAN_VERSION
    CLEAN_VERSION="${PACKAGE_VERSION//-/.}"

    # Copy pyproject.toml from the script directory and replace the version placeholder
    log_info "Preparing pyproject.toml..."
    if [[ -f "${SCRIPT_DIR}/pyproject.toml" ]]; then
        sed "s/{PACKAGE_VERSION}/${CLEAN_VERSION}/g" "${SCRIPT_DIR}/pyproject.toml" > pyproject.toml
    else
        log_error "Static pyproject.toml template not found in ${SCRIPT_DIR}"
        false
    fi

    # Build wheel into dist/ so template and powercore can collect, repair, and process it
    log_info "Building wheel into dist/..."
    mkdir -p dist
    python -m pip wheel --no-deps -w dist .
    python -m pip install dist/*.whl
}

# =============================================================================
# CALLBACK: custom_test_command — verify imported package
# =============================================================================
custom_test_command() {
    log_info "Verifying thriftcpp package import..."
    python -c "import thriftcpp; print('thriftcpp imported successfully')"
}

# =============================================================================
# Build Configuration
# =============================================================================
BUILD_WHEEL="true"
LICENSE_SPDX="Apache-2.0"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
