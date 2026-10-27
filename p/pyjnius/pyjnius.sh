#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyjnius
# Version       : 1.6.1
# Source repo   : https://github.com/kivy/pyjnius
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Prerna Kumbhar <Prerna.Kumbhar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyjnius"
PACKAGE_VERSION="${1:-1.6.1}"
PACKAGE_URL="https://github.com/kivy/pyjnius"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make python3-devel java-17-openjdk java-17-openjdk-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — apply ppc64le compatibility patch
# =============================================================================
post_clone() {
    log_info "Applying pyjnius ppc64le patch"
    git apply "${SCRIPT_DIR}/patches/pyjnius.patch"
}

# =============================================================================
# CALLBACK: pre_build — install Cython<3 required to compile jnius.pyx extension
# =============================================================================
pre_build() {
    log_info "Installing Cython and build dependencies"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "Cython<3"
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps and compile Java test classes
# .venv-test is isolated from .venv-build; deps must be re-installed here.
# =============================================================================
pre_test() {
    log_info "Installing build dependencies into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "Cython<3"
    log_info "Compiling Java test classes"
    mkdir -p tests/java-classes
    javac -encoding UTF-8 -d tests/java-classes $(find tests/java-src -name "*.java")
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest against the installed jnius package
# The wheel installed into .venv-test contains the compiled .so extension.
# The source jnius/ directory is removed so Python resolves jnius from the
# installed package rather than the bare source tree which lacks the .so.
# =============================================================================
custom_test_command() {
    export CLASSPATH="${PWD}/tests/java-classes"
    log_info "Removing source jnius/ to expose installed package"
    rm -rf jnius/
    log_info "Running pyjnius test suite"
    python -m pytest -v tests/
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
