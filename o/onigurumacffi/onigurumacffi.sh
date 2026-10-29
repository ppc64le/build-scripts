#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : onigurumacffi
# Version       : 1.5.0
# Source repo   : https://github.com/asottile/onigurumacffi
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <ppc64le@lists.ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="onigurumacffi"
PACKAGE_VERSION="${1:-1.5.0}"
PACKAGE_URL="https://github.com/asottile/onigurumacffi"

# No pyproject.toml in this repo — use a safe setuptools upper bound
SETUPTOOLS_VERSION="<82"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
# oniguruma-devel provides the oniguruma headers and libonig required by the
# CFFI build step (onigurumacffi_build.py links against -lonig).
RH_DEP_PKGS="git gcc oniguruma-devel python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install cffi so the CFFI build step can find it
# =============================================================================
pre_build() {
    log_info "Installing cffi build dependency"
    python -m pip install "cffi>=1"
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into the test venv
# =============================================================================
pre_test() {
    log_info "Installing pip, setuptools, and wheel into test venv"
    python -m pip install --upgrade pip setuptools wheel
    log_info "Installing cffi into test venv"
    python -m pip install "cffi>=1"
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest directly, bypassing tox coverage plugins
# =============================================================================
custom_test_command() {
    # tox.ini runs coverage via covdefaults which is not installed in the test venv.
    # Run pytest directly to avoid the tox/coverage dependency chain.
    log_info "Running onigurumacffi tests"
    python -m pip uninstall -y pytest-cov covdefaults 2>/dev/null || true
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        tests/
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
