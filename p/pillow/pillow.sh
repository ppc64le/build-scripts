#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pillow
# Version       : 12.3.0
# Source repo   : https://github.com/python-pillow/Pillow
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts@ibm.com>
#
# Notes:
#   - Imaging library with C extensions (provides PROVIDES_ARTIFACT="pillow")
#   - Requires libjpeg-turbo and zlib for image format support
#   - Pillow 12+ requires pybind11>=2.13.0 at build time (installed in pre_build/pre_test)
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pillow"
PACKAGE_VERSION="${1:-12.3.0}"
PACKAGE_URL="https://github.com/python-pillow/Pillow"

# Note: Pillow repo is named "Pillow" (capital P), but package name is "pillow"
CLONE_DIR="Pillow"

# =============================================================================
# Artifact Declaration (Tier 0 - no artifact dependencies)
# =============================================================================
PROVIDES_ARTIFACT="pillow"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel libpng-devel libtiff-devel freetype-devel python3 python3-devel python3-pip"
DEB_DEP_PKGS=""   # not yet validated on Debian/Ubuntu
SLES_DEP_PKGS=""  # not yet validated on SLES

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="MIT-CMU"

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
        SETUPTOOLS_VERSION="<82"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: custom_install — build wheel and register pillow as an artifact
# =============================================================================
# Builds the pillow wheel, installs it into the venv, copies it to the
# artifact directory, and writes env.sh + manifest so downstream packages
# can consume it via BUILD_DEPS="pillow".
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    # Idempotency — skip if already built
    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Pillow artifact already exists at ${ARTIFACT_DIR}"
        return
    fi

    log_info "Building pillow ${PACKAGE_VERSION} wheel..."
    mkdir -p "${ARTIFACT_DIR}/wheels"

    # Install build tools (pybind11 already installed by pre_build for Pillow 12+)
    python -m pip install --upgrade pip "setuptools${SETUPTOOLS_VERSION-<70}" build wheel auditwheel patchelf

    # Build the wheel
    python -m build --no-isolation --wheel --outdir dist/

    # Repair the wheel with auditwheel to bundle native libs
    local raw_wheel
    raw_wheel=$(ls dist/pillow-*.whl dist/Pillow-*.whl 2>/dev/null | head -1)
    if [[ -z "${raw_wheel}" ]]; then
        log_error "No pillow wheel found in dist/ after build"
        false
    fi

    log_info "Repairing wheel: $(basename "${raw_wheel}")"
    if auditwheel repair "${raw_wheel}" -w dist/wheelhouse/ 2>&1 | grep -q "Fixed-up wheel written to"; then
        log_info "Wheel repaired successfully"
    else
        log_info "Wheel already compliant or pure-Python — using as-is"
        mkdir -p dist/wheelhouse
        cp "${raw_wheel}" dist/wheelhouse/
    fi

    local repaired_wheel
    repaired_wheel=$(ls dist/wheelhouse/pillow-*.whl dist/wheelhouse/Pillow-*.whl 2>/dev/null | head -1)

    # Install wheel into the current venv
    log_info "Installing pillow wheel into venv..."
    python -m pip install --no-deps "${repaired_wheel}"

    # Copy wheel to artifact directory for downstream consumers
    cp "${repaired_wheel}" "${ARTIFACT_DIR}/wheels/"
    log_info "Wheel stored at: ${ARTIFACT_DIR}/wheels/$(basename "${repaired_wheel}")"

    # Copy license
    if [[ -f "LICENSE" ]]; then
        cp LICENSE "${ARTIFACT_DIR}/"
    fi

    # Write env.sh — exposes wheel path so downstream BUILD_DEPS="pillow" can install it
    cat > "${ARTIFACT_DIR}/env.sh" << EOF
# pillow ${PACKAGE_VERSION} artifact environment
# Provides the pre-built pillow wheel for downstream packages.
# Usage in dependent scripts: BUILD_DEPS="pillow"

export PILLOW_PREFIX="${ARTIFACT_DIR}"
export PILLOW_WHEEL_DIR="${ARTIFACT_DIR}/wheels"
export PILLOW_VERSION="${PACKAGE_VERSION}"
EOF

    # Generate manifest
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "pillow" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}"

    log_info "Pillow artifact registered at ${ARTIFACT_DIR}"
}

# =============================================================================
# CALLBACK: pre_build — install pybind11 for Pillow 12+ (required by setup.py)
# =============================================================================
# Pillow 12+ imports pybind11 in setup.py at load time. Because the build uses
# --no-isolation, pybind11 must be present in .venv-build before invocation.
_pillow_major="${PACKAGE_VERSION%%.*}"
if [[ "$_pillow_major" -ge 12 ]] 2>/dev/null; then
    pre_build() {
        log_info "Pillow ${PACKAGE_VERSION}: installing pybind11 (required by setup.py since 12.0.0)"
        python -m pip install "pybind11>=2.13.0"
    }
fi

# =============================================================================
# CALLBACK: pre_test — mirror pre_build deps into .venv-test
# =============================================================================
if [[ "${_pillow_major}" -ge 12 ]] 2>/dev/null; then
    pre_test() {
        log_info "Pillow ${PACKAGE_VERSION}: installing pybind11 in test venv (mirrors pre_build)"
        python -m pip install "pybind11>=2.13.0"
    }
fi
unset _pillow_major  # used by pre_build and pre_test guards above

# =============================================================================
# CALLBACK: custom_test_command — run test suite, skip OSS-Fuzz test
# =============================================================================
# Tests/oss-fuzz/test_fuzzers.py imports 'fuzzers', a module only available
# inside Google OSS-Fuzz infrastructure. --deselect is applied after collection
# so the import error still aborts pytest; --ignore prevents collection entirely.
# test_segfault loads a malformed fuzz font; FreeType on ppc64le raises
# OSError: unknown file format instead of the expected exception.
custom_test_command() {
    log_info "Running pillow test suite (ignoring oss-fuzz test, deselecting ppc64le-specific font crash)"
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --ignore=Tests/oss-fuzz/test_fuzzers.py \
        --deselect Tests/test_font_crash.py::TestFontCrash::test_segfault
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
