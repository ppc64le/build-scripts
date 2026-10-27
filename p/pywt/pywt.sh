#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pywt
# Version       : v1.8.0
# Source repo   : https://github.com/PyWavelets/pywt
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pywt"
PACKAGE_VERSION="${1:-v1.8.0}"
PACKAGE_URL="https://github.com/PyWavelets/pywt"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git zlib-devel openssl-devel bzip2-devel libffi-devel libjpeg-turbo-devel python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

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
        # No pyproject.toml (v1.4.1 uses setup.py) — pin setuptools for legacy build
        SETUPTOOLS_VERSION="<65"
        log_info "No pyproject.toml found — falling back to SETUPTOOLS_VERSION='${SETUPTOOLS_VERSION}'"
    fi
}

# =============================================================================
# CALLBACK: pre_build — version-aware build deps
# v1.4.1: legacy setup.py build — requires Cython<3 and pinned numpy
# v1.8.0+: meson-python build — requires Cython>=3 and numpy>=2
# =============================================================================
pre_build() {
    if [[ "${PACKAGE_VERSION}" == "v1.4.1" ]]; then
        # v1.4.1 — legacy setup.py build system
        log_info "Installing legacy build deps for pywt ${PACKAGE_VERSION}..."
        # numpy 1.21.6 does not support Python 3.11+; use 1.23.3 there
        local lang_ver=(${PYTHON_VERSION//./ })
        if [[ ${lang_ver[0]} -gt 3 ]] || [[ ${lang_ver[0]} -eq 3 && ${lang_ver[1]} -ge 11 ]]; then
            python -m pip install "numpy==1.23.3"
        else
            python -m pip install "numpy==1.21.6"
        fi
        python -m pip install "Cython<3.0,>=0.29.24"
    else
        # v1.8.0+ — meson-python build system
        log_info "Installing meson-python build deps for pywt ${PACKAGE_VERSION}..."
        python -m pip install meson ninja meson-python
        python -m pip install "cython>=3.0" "numpy>=2.0"
    fi
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into the test venv
# =============================================================================
pre_test() {
    log_info "Installing build backend and mirrored build deps into test venv..."
    python -m pip install --upgrade pip setuptools wheel

    if [[ "${PACKAGE_VERSION}" == "v1.4.1" ]]; then
        # v1.4.1 — mirror legacy build deps; must exactly match the numpy
        # version used in pre_build() to avoid ABI mismatch
        local lang_ver=(${PYTHON_VERSION//./ })
        if [[ ${lang_ver[0]} -gt 3 ]] || [[ ${lang_ver[0]} -eq 3 && ${lang_ver[1]} -ge 11 ]]; then
            python -m pip install "numpy==1.23.3"
        else
            python -m pip install "numpy==1.21.6"
        fi
        python -m pip install "Cython<3.0,>=0.29.24"
        log_info "Installing test dependencies..."
        # Do NOT install matplotlib here — it requires numpy>=1.25 which would
        # override the numpy==1.21.6/1.23.3 pin and cause an ABI mismatch
        python -m pip install "pytest<9"
    else
        # v1.8.0+ — mirror meson-python build deps
        python -m pip install meson ninja meson-python
        # pytest<9: pywt uses itertools.product in @pytest.mark.parametrize
        # which became a hard collection error in pytest 9
        # numpy<2: pywt tests use numpy.testing.assert_warns removed in NumPy 2.x
        python -m pip install "cython>=3.0" "numpy<2"
        log_info "Installing test dependencies..."
        python -m pip install "pytest<9" matplotlib pillow
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest against the installed pywt package
# =============================================================================
custom_test_command() {
    log_info "Running pytest against installed pywt package..."
    python -m pip uninstall -y pytest-cov pytest-xdist 2>/dev/null
    # CWD is inside the clone root so 'pywt/' source dir shadows the installed
    # wheel on sys.path. Prepend all site-packages paths (lib and lib64) via
    # PYTHONPATH so the installed wheel's compiled .so extensions are found
    # first. Pass the absolute path to the installed tests directory so pytest
    # never touches the source tree.
    # pywt/tests has no __init__.py so --pyargs pywt.tests does not work.
    PYTHONPATH="$(python -c 'import site; print(":".join(site.getsitepackages()))')${PYTHONPATH:+:$PYTHONPATH}" \
    python -m pytest "$(python -c 'import site; print(site.getsitepackages()[0])')/pywt/tests" \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
