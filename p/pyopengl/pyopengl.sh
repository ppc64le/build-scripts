#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyopengl
# Version       : 3.1.10
# Source repo   : https://github.com/mcfletch/pyopengl
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyopengl"
PACKAGE_VERSION="${1:-3.1.10}"
PACKAGE_URL="https://github.com/mcfletch/pyopengl"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel mesa-libGL"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Pure Python — no compiled C/Cython extensions in the main package
NOARCH="true"

# =============================================================================
# CALLBACK: custom_test_command — run only the two headless tests that need
#   no GPU, no EGL device, no pygame display context:
#     - test_check_import_err            : imports OpenGL.GLU (pure Python binding check)
#     - test_check_silence_numpy_warning : array dtype test, zero GL calls
#   test_check_gles_imports is excluded: it sets PYOPENGL_PLATFORM=egl and
#   requires libGLESv2.so which is not present in the UBI CI container.
#   All remaining tests in tests/ require pygame + a live display or EGL device.
# =============================================================================
custom_test_command() {
    log_info "Running headless PyOpenGL tests (no GPU/display required)"
    python -m pytest tests/test_checks.py \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        -k "test_check_import_err or test_check_silence_numpy_warning"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

