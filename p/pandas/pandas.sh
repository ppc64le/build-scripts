#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package   : pandas
# Version   : v2.2.3
# Source repo : https://github.com/pandas-dev/pandas
# Tested on  : UBI:9.6
# Language   : Python
# Script License: Apache License, Version 2 or later
# Maintainer  : Build Scripts Team <build-scripts@ibm.com>
# -----------------------------------------------------------------------------
 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 
# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pandas"
PACKAGE_VERSION="${1:-v2.2.3}"
PACKAGE_URL="https://github.com/pandas-dev/pandas"
BUILD_DEPS="numpy"
PROVIDES_ARTIFACT="pandas"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel sqlite-devel libffi-devel zlib-devel bzip2-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# HELPER: install numpy artifact wheel or download matching numpy version into active venv.
# Used by both pre_build and pre_test.
# =============================================================================
_install_artifact_wheels() {
    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    local numpy_wheel=""
    if [[ -n "${NUMPY_PREFIX:-}" && -d "${NUMPY_PREFIX}/wheels" ]]; then
        numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" 2>/dev/null | head -1)
    fi

    if [[ -n "${numpy_wheel}" ]]; then
        log_info "Installing NumPy wheel: ${numpy_wheel}"
        python -m pip install --no-deps --ignore-installed "${numpy_wheel}"
        # Remove the artifact site-packages from PYTHONPATH so the venv copy wins.
        if [[ -n "${NUMPY_PREFIX:-}" ]]; then
            local numpy_site="${NUMPY_PREFIX}/lib/python$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")/site-packages"
            while [[ "${PYTHONPATH:-}" == "${numpy_site}" || "${PYTHONPATH:-}" == "${numpy_site}:"* ]]; do
                [[ "${PYTHONPATH}" == "${numpy_site}" ]] && { unset PYTHONPATH; break; }
                export PYTHONPATH="${PYTHONPATH#${numpy_site}:}"
            done
        fi
    elif [[ -n "${NUMPY_PREFIX:-}" && -d "${NUMPY_PREFIX}" ]]; then
        log_warn "No numpy wheel for ${python_abi} found in artifact — using artifact PYTHONPATH"
    else
        log_info "No NumPy artifact directory found — installing NumPy"
        python -m pip install numpy
    fi
}

# =============================================================================
# CALLBACK: post_clone — apply meson.build patch to hardcode NumPy include path
# PANDAS_MESON_PATCH is injected by powercore from build_info.json patches section.
# v2.x patch uses 2-space indentation; v3.x patch uses 4-space indentation with trailing commas.
# Fallback: resolve patch from SCRIPT_DIR when running outside powercore.
# =============================================================================
post_clone() {
    if [[ -z "${PANDAS_MESON_PATCH:-}" ]]; then
        local pkg_major="${PACKAGE_VERSION%%.*}"
        pkg_major="${pkg_major#v}"
        if [[ "${pkg_major}" -ge 3 ]]; then
            PANDAS_MESON_PATCH="${SCRIPT_DIR}/patches/meson-numpy-include-3x.patch"
        else
            PANDAS_MESON_PATCH="${SCRIPT_DIR}/patches/meson-numpy-include.patch"
        fi
    fi
    log_info "Applying meson-numpy-include patch to pandas/meson.build"
    git apply "${PANDAS_MESON_PATCH}"
}

# =============================================================================
# CALLBACK: pre_build — install meson-python build system, Cython, and copy NumPy headers
# =============================================================================
pre_build() {
    log_info "Installing artifact wheels into build venv"
    _install_artifact_wheels

    log_info "Installing pandas build-system requirements (pandas ${PACKAGE_VERSION})"
    python -m pip install meson-python meson ninja "Cython>=3.0.5" "versioneer[toml]"

    # Meson rejects include paths that are inside the source tree (e.g. a venv
    # created inside the clone dir). Copying headers to /tmp/numpy-include gives
    # meson a path that is always outside the source tree. The patch hardcodes
    # this same /tmp/numpy-include path into pandas/meson.build via post_clone.
    local numpy_include
    numpy_include=$(python -c "import numpy; print(numpy.get_include())")
    log_info "Copying NumPy headers: ${numpy_include} -> /tmp/numpy-include"
    rm -rf /tmp/numpy-include && cp -a "${numpy_include}" /tmp/numpy-include
}

# =============================================================================
# CALLBACK: custom_install — build wheel bypassing unmet build-system dependency pins
# =============================================================================
custom_install() {
    log_info "Building pandas ${PACKAGE_VERSION} wheel from source"
    python -m build --no-isolation --wheel --skip-dependency-check
}

# =============================================================================
# CALLBACK: pre_test — install numpy artifact and pandas runtime deps into test venv
# =============================================================================
pre_test() {
    log_info "Installing artifact wheels into test venv"
    _install_artifact_wheels

    log_info "Installing test runtime dependencies"
    python -m pip install python-dateutil pytz tzdata
}
 
# =============================================================================
# CALLBACK: custom_test_command — run import smoke test from neutral directory
# to avoid source tree shadowing the installed C extensions
# =============================================================================
custom_test_command() {
    (cd /tmp && python -c "
import pandas as pd
import numpy as np
print('pandas version:', pd.__version__)
print('numpy version:', np.__version__)

# Basic Series and DataFrame smoke tests
s = pd.Series([10, 20, 30])
assert len(s) == 3, 'Series length mismatch'

df = pd.DataFrame({'x': [1, 2], 'y': [3, 4]})
assert list(df.columns) == ['x', 'y'], 'Column names mismatch'

print('pandas smoke test passed!')
")
}
 
# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"


