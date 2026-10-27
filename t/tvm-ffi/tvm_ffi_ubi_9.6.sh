#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tvm-ffi
# Version       : v0.1.9
# Source repo   : https://github.com/apache/tvm-ffi
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tvm-ffi"
PACKAGE_VERSION="${1:-v0.1.9}"
PACKAGE_URL="https://github.com/apache/tvm-ffi"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make cmake ninja-build python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — exclude .venv-build from the sdist
# scikit-build-core uses 'git ls-files' to collect sdist sources; the template
# creates .venv-build inside the repo dir which contains absolute symlinks.
# Python 3.10 tarfile's security filter raises AbsoluteLinkError on those symlinks.
# Adding .venv-build to .gitignore makes git ls-files skip it entirely.
# =============================================================================
post_clone() {
    log_info "Excluding .venv-build from git-tracked files to prevent tarfile AbsoluteLinkError"
    echo '.venv-build' >> .gitignore
    echo '.venv-test'  >> .gitignore
}

# =============================================================================
# CALLBACK: pre_build — upgrade setuptools so scikit-build-core>=0.10.0 can install,
# then install the build backend, cython, setuptools-scm, and numpy
# scikit-build-core requires setuptools>=70; template default pins setuptools<70
# =============================================================================
pre_build() {
    log_info "Upgrading pip and setuptools to satisfy scikit-build-core>=0.10.0 requirement"
    python -m pip install --upgrade pip "setuptools>=70" wheel
    log_info "Installing build-system requirements: scikit-build-core, cython, setuptools-scm, ninja, cmake"
    python -m pip install "scikit-build-core>=0.10.0" "cython>=3.0" setuptools-scm "ninja>=1.11" cmake
    log_info "Installing runtime build dependency: numpy"
    python -m pip install numpy
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into test venv; ensure build backend present
# scikit-build-core requires setuptools>=70; must upgrade before installing it
# =============================================================================
pre_test() {
    log_info "Upgrading pip and setuptools in test venv"
    python -m pip install --upgrade pip "setuptools>=70" wheel
    log_info "Mirroring build deps into test venv: scikit-build-core, cython, setuptools-scm, ninja, cmake"
    python -m pip install "scikit-build-core>=0.10.0" "cython>=3.0" setuptools-scm "ninja>=1.11" cmake
    log_info "Installing numpy into test venv"
    python -m pip install numpy
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
