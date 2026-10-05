#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : matplotlib
# Version       : v3.10.3
# Source repo   : https://github.com/matplotlib/matplotlib
# Tested on     : UBI:9.6
# Language      : Python, C++
# Script License: Apache License, Version 2 or later
# Maintainer    : shivansh.s1@ibm.com
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="matplotlib"
PACKAGE_VERSION="${1:-v3.10.3}"
PACKAGE_URL="https://github.com/matplotlib/matplotlib"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building matplotlib
# Note: gcc/g++, cmake are provided by the container
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip openblas-devel ninja-build zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel freetype-devel pkg-config"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv libopenblas-dev ninja-build zlib1g zlib1g-dev libjpeg-dev libfreetype6-dev pkg-config"
SLES_DEP_PKGS="git python3-devel python3-pip openblas-devel ninja zlib-devel libjpeg-devel freetype-devel pkg-config"

# =============================================================================
# Global version components — parsed once, reused by all callbacks
# =============================================================================
_mpl_ver="${PACKAGE_VERSION#v}"
_mpl_major="${_mpl_ver%%.*}"
_mpl_minor="${_mpl_ver#*.}"; _mpl_minor="${_mpl_minor%%.*}"

# =============================================================================
# CALLBACK: post_clone — apply version-specific patch for qhull on v3.7/v3.8;
# For v3.9+: No action needed - meson wrap system handles qhull automatically
# =============================================================================
post_clone() {
    if [[ "${_mpl_major}" -eq 3 ]] && [[ "${_mpl_minor}" -le 8 ]]; then
        # v3.7-v3.8: Apply version-specific patch for qhull 8.0.2 (version + download URL)
        local PATCH_FILE

        if [[ "${_mpl_minor}" -eq 7 ]]; then
            # v3.7.x: Updates qhull version and download URL in setupext.py
            PATCH_FILE="${SCRIPT_DIR}/patches/matplotlib_v3.7.patch"
            log_info "Applying patch for v3.7.x..."
        elif [[ "${_mpl_minor}" -eq 8 ]]; then
            # v3.8.x: Only setupext.py changes (pyproject.toml already has numpy>=1.25)
            PATCH_FILE="${SCRIPT_DIR}/patches/matplotlib_v3.8.patch"
            log_info "Applying patch for v3.8.x..."
        fi

        if [[ -f "${PATCH_FILE}" ]]; then
            log_info "Found patch file: ${PATCH_FILE}"
            if ! git apply "${PATCH_FILE}"; then
                log_error "Failed to apply patch: ${PATCH_FILE}"
                return 1
            fi
            log_info "Patch applied successfully"
        else
            log_warn "No patch file found"
            log_warn "Expected: ${PATCH_FILE}"
        fi

        # Set SETUPTOOLS_SCM_PRETEND_VERSION to force the correct version
        # This prevents setuptools_scm from detecting git history and generating dev versions
        export SETUPTOOLS_SCM_PRETEND_VERSION="${PACKAGE_VERSION#v}"
        log_info "Set SETUPTOOLS_SCM_PRETEND_VERSION=${SETUPTOOLS_SCM_PRETEND_VERSION}"
    fi
}

# =============================================================================
# CALLBACK: pre_build — install build dependencies and validate Python version
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    # 1. Python version validation for matplotlib v3.10+
    # Check if Package Version >= 3.10: (Major > 3) OR (Major == 3 AND Minor >= 10)
    if [[ "${_mpl_major}" -gt 3 ]] 2>/dev/null || { [[ "${_mpl_major}" -eq 3 ]] && [[ "${_mpl_minor}" -ge 10 ]]; } 2>/dev/null; then
        local _lang_ver _lang_major _lang_minor
        _lang_ver="${LANGUAGE_VERSION#v}"
        _lang_major="${_lang_ver%%.*}"
        _lang_minor="${_lang_ver#*.}"; _lang_minor="${_lang_minor%%.*}"

        # Check if Python < 3.10: (Major == 3 AND Minor < 10)
        if [[ "${_lang_major}" -eq 3 ]] && [[ "${_lang_minor}" -lt 10 ]]; then
            log_error "matplotlib ${PACKAGE_VERSION} does not support Python ${LANGUAGE_VERSION}. Requires Python 3.10+."
            return 1
        fi
    fi

    # 2. Read pyproject.toml once and install both [build-system].requires and
    #    [project].dependencies from a single Python process (avoids importing
    #    tomllib/tomli twice).
    #
    #    [build-system].requires is installed as-is, including oldest-supported-numpy
    #    for v3.7.x — setuptools re-reads pyproject.toml at build time and validates
    #    every entry is present in the venv, so we must not skip it.
    #
    #    [project].dependencies is installed with numpy entries skipped — numpy is
    #    handled separately in step 3 for v3.9+ (meson needs headers at compile time
    #    but does not declare numpy in [build-system].requires).
    #    For v3.7/v3.8, [project].dependencies is empty (metadata lives in setup.cfg).
    log_info "Installing pyproject.toml dependencies ([build-system].requires and [project].dependencies)..."
    python -c "
try:
    import tomllib
except ImportError:
    import tomli as tomllib
import subprocess, sys
with open('pyproject.toml', 'rb') as f:
    data = tomllib.load(f)

# [build-system].requires — install everything as declared (incl. oldest-supported-numpy)
requires = data.get('build-system', {}).get('requires', [])
for req in requires:
    print(f'Installing build-system req: {req}')
    subprocess.run([sys.executable, '-m', 'pip', 'install', req], check=True)

# [project].dependencies — skip numpy (handled separately for v3.9+)
deps = data.get('project', {}).get('dependencies', [])
for dep in deps:
    if dep.lower().startswith('numpy'):
        print(f'Skipping numpy (handled separately): {dep}')
        continue
    print(f'Installing project dep: {dep}')
    subprocess.run([sys.executable, '-m', 'pip', 'install', dep], check=True)
"

    # 3. v3.9+ also needs meson and ninja (not in [build-system].requires directly)
    if [[ "${_mpl_major}" -eq 3 ]] && [[ "${_mpl_minor}" -ge 9 ]]; then
        log_info "Installing meson and ninja for v3.9+ build backend..."
        python -m pip install meson ninja
    fi

    # 4. Pre-install numpy for v3.9+ only.
    #    Meson needs numpy headers at compile time but does not declare numpy in
    #    [build-system].requires, so it must be installed before python -m build runs.
    #    For v3.7/v3.8 this step is intentionally skipped — numpy is already installed
    #    by [build-system].requires in step 2 (oldest-supported-numpy for v3.7,
    #    numpy>=1.25 for v3.8). Installing it again would upgrade past the
    #    oldest-supported-numpy pin and break setuptools' dependency check.
    #    numpy version ranges are empirical ppc64le/s390x compatibility fixes.
    #    v3.9.x : numpy>=2.0.0rc1,<2.3  (v3.9.4 fails with numpy 2.4+)
    #    v3.10+  : numpy>=2.0            (no upper bound needed)
    if [[ "${_mpl_major}" -eq 3 ]] && [[ "${_mpl_minor}" -eq 9 ]]; then
        log_info "Installing numpy>=2.0.0rc1,<2.3 for v3.9.x..."
        python -m pip install 'numpy>=2.0.0rc1,<2.3'
    elif [[ "${_mpl_major}" -gt 3 ]] || { [[ "${_mpl_major}" -eq 3 ]] && [[ "${_mpl_minor}" -ge 10 ]]; }; then
        log_info "Installing numpy>=2.0 for v3.10+..."
        python -m pip install 'numpy>=2.0'
    fi
    # v3.7/v3.8: numpy already in venv from step 2 — do not reinstall
}

# =============================================================================
# CALLBACK: custom_test_command — install in editable mode and run matplotlib test suite
# For v3.9+, meson handles qhull via wrap system automatically
# For v3.7-v3.8, setuptools handles the build
# =============================================================================
custom_test_command() {
    if [[ "${_mpl_major}" -eq 3 ]] && [[ "${_mpl_minor}" -ge 9 ]]; then
        # v3.9+: Use meson-python with editable install
        log_info "Installing build dependencies for editable install (v3.9+)..."

        # Install meson-python, build tools, and setuptools_scm for editable install
        python -m pip install 'meson-python>=0.13.1,<0.17.0' meson ninja pybind11 'setuptools_scm>=7'

        log_info "Installing matplotlib in editable mode (v3.9+ with meson wrap)..."

        # For v3.9+, meson's wrap system handles qhull automatically
        # No manual qhull download needed - qhull.wrap file manages it
        python -m pip install --no-build-isolation -e .[dev]

    else
        # v3.7-v3.8: Install from wheel and copy test data files
        # Setuptools in these versions doesn't support editable install properly
        log_info "Installing matplotlib from wheel (v3.7-v3.8)..."

        # IMPORTANT: Install numpy<2 first to match the build environment
        log_info "Installing numpy<2 to match build environment..."
        python -m pip install 'numpy<2'

        # Install the wheel that was built
        python -m pip install dist/*.whl

        # Copy test data files to the installed location
        log_info "Copying test data files (baseline_images, tinypages, etc.)..."

        # Get the site-packages location where matplotlib is installed
        local site_packages=$(python -c "import site; print(site.getsitepackages()[0])")
        local mpl_install_dir="${site_packages}/matplotlib"

        # Copy test data directories if they exist in the source
        if [[ -d "lib/matplotlib/tests/baseline_images" ]]; then
            log_info "Copying baseline_images..."
            mkdir -p "${mpl_install_dir}/tests/"
            cp -r lib/matplotlib/tests/baseline_images "${mpl_install_dir}/tests/" 2>/dev/null || true
        fi

        if [[ -d "lib/matplotlib/tests/tinypages" ]]; then
            log_info "Copying tinypages..."
            mkdir -p "${mpl_install_dir}/tests/"
            cp -r lib/matplotlib/tests/tinypages "${mpl_install_dir}/tests/" 2>/dev/null || true
        fi

        # Copy mpl-data if needed
        if [[ -d "lib/matplotlib/mpl-data" ]]; then
            log_info "Copying mpl-data..."
            cp -r lib/matplotlib/mpl-data "${mpl_install_dir}/" 2>/dev/null || true
        fi

        log_info "Test data files copied successfully."
    fi

    log_info "Running matplotlib test suite (test_units.py)..."

    # Run tests using --pyargs (matplotlib installed in editable mode)
    python -m pytest \
        --import-mode=importlib \
        --pyargs matplotlib.tests.test_units \
        -o "addopts=" \
        -W ignore::DeprecationWarning \
        -W ignore::ResourceWarning \
        -v
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
