#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : scikit-learn
# Version       : 1.7.0
# Source repo   : https://github.com/scikit-learn/scikit-learn
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="scikit-learn"
PACKAGE_VERSION="${1:-1.7.0}"
PACKAGE_URL="https://github.com/scikit-learn/scikit-learn"

# =============================================================================
# Artifact dependencies and declaration
# =============================================================================
NUMPY_ARTIFACT_VERSION="${NUMPY_ARTIFACT_VERSION:-v2.2.5}"
SCIPY_ARTIFACT_VERSION="${SCIPY_ARTIFACT_VERSION:-v1.15.2}"
BUILD_DEPS=${BUILD_DEPS:-"numpy:${NUMPY_ARTIFACT_VERSION} scipy:${SCIPY_ARTIFACT_VERSION}"}
PROVIDES_ARTIFACT="scikit-learn"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran make cmake python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# Version Compatibility Check
# Python 3.9 and 3.10 support is removed (only Python 3.11+ is supported)
# scikit-learn <= 1.1.x is unsupported on Python 3.11+
# scikit-learn 1.3.x is supported on Python 3.11 only (distutils removed in 3.12)
# scikit-learn 1.5.x+ supports Python 3.11 - 3.13
# =============================================================================
_sklearn_ver="${PACKAGE_VERSION#v}"
_sklearn_major="${_sklearn_ver%%.*}"
_sklearn_minor="${_sklearn_ver#*.}"
_sklearn_minor="${_sklearn_minor%%.*}"
_py_minor="${PYTHON_VERSION#3.}"
_py_minor="${_py_minor%%.*}"
_sklearn_unsupported_reason=""
_sklearn_unsupported_hint=""

if [[ -n "$_py_minor" ]]; then
    if [[ "$_py_minor" -lt 11 ]]; then
        _sklearn_unsupported_reason="Python ${PYTHON_VERSION} (< 3.11) is not supported for scikit-learn"
        _sklearn_unsupported_hint="Use Python 3.11+ for building scikit-learn"
    elif [[ "$_sklearn_major" -eq 1 && "$_sklearn_minor" -le 1 ]]; then
        _sklearn_unsupported_reason="scikit-learn <= 1.1.x is not supported on Python 3.11+ (requires Python <= 3.10)"
        _sklearn_unsupported_hint="Use scikit-learn 1.3+ for Python ${PYTHON_VERSION}"
    elif [[ "$_sklearn_major" -eq 1 && "$_sklearn_minor" -eq 3 && "$_py_minor" -ge 12 ]]; then
        _sklearn_unsupported_reason="scikit-learn 1.3.x is not supported on Python 3.12+ (distutils removed in Python 3.12)"
        _sklearn_unsupported_hint="Use scikit-learn 1.5+ for Python ${PYTHON_VERSION}"
    fi
fi

if [[ -n "${_sklearn_unsupported_reason}" ]]; then
    echo "UNSUPPORTED: ${_sklearn_unsupported_reason}"
    echo "${_sklearn_unsupported_hint}"
    false
fi

unset _sklearn_ver _sklearn_major _sklearn_minor _py_minor _sklearn_unsupported_reason _sklearn_unsupported_hint

# Helper: install pyproject build-system dependencies dynamically
install_pyproject_dependencies() {
    log_info "Preparing scikit-learn build dependency installation..."

    if [[ -f "pyproject.toml" ]]; then
        # Create a unique temporary requirements file using coreutils mktemp
        local req_file
        req_file="$(mktemp)"
        log_info "Installing tomli for pyproject.toml parsing"
        python -m pip install tomli

        log_info "Reading scikit-learn build-system requirements from pyproject.toml"
        python - "${req_file}" <<'PY'
import sys

try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

with open("pyproject.toml", "rb") as f:
    requires = tomllib.load(f).get("build-system", {}).get("requires", [])

with open(sys.argv[1], "w", encoding="utf-8") as out:
    for req in requires:
        print(req, file=out)
PY

        if [[ -s "${req_file}" ]]; then
            log_info "Installing scikit-learn build dependencies from pyproject.toml"
            python -m pip install -r "${req_file}"
        fi
        # Clean up temporary requirements file
        rm -f "${req_file}"
    else
        log_warn "pyproject.toml not found; using fallback build dependencies"
        python -m pip install "meson-python>=0.16.0,<0.19.0" "Cython>=3.0.10,<3.2.0" ninja
    fi

    log_info "Installing additional scikit-learn build tooling"
    python -m pip install ninja "patchelf>=0.11.0" joblib threadpoolctl
}

# =============================================================================
# CALLBACK: pre_build — set up openblas/numpy/scipy artifacts and build deps
# =============================================================================
pre_build() {
    log_info "Configuring scikit-learn build environment..."

    # Configure to use openblas from artifact
    if [[ -n "${OPENBLAS_PREFIX:-}" ]]; then
        log_info "Using OpenBLAS from artifact: ${OPENBLAS_PREFIX}"
        export PKG_CONFIG_PATH="${OPENBLAS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
        export CMAKE_PREFIX_PATH="${OPENBLAS_PREFIX}:${CMAKE_PREFIX_PATH:-}"
    fi

    # Install NumPy and SciPy wheels from artifacts if available
    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    if [[ -n "${NUMPY_PREFIX:-}" ]]; then
        log_info "Using NumPy from artifact: ${NUMPY_PREFIX}"
        local numpy_wheel
        numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
        if [[ -n "${numpy_wheel}" ]]; then
            log_info "Installing NumPy wheel from artifact: ${numpy_wheel}"
            python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
        fi
    fi

    if [[ -n "${SCIPY_PREFIX:-}" ]]; then
        log_info "Using SciPy from artifact: ${SCIPY_PREFIX}"
        local scipy_wheel
        scipy_wheel=$(find "${SCIPY_PREFIX}/wheels" -name "scipy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
        if [[ -n "${scipy_wheel}" ]]; then
            log_info "Installing SciPy wheel from artifact: ${scipy_wheel}"
            python -m pip install --force-reinstall --no-deps "${scipy_wheel}"
        fi
    fi

    # Install Python build dependencies dynamically from pyproject.toml
    install_pyproject_dependencies
}

# =============================================================================
# CALLBACK: post_build — package scikit-learn artifact (env.sh + wheels/) for consumers
# =============================================================================
post_build() {
    log_info "Packaging scikit-learn artifact..."

    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "scikit-learn" "${PACKAGE_VERSION}")"

    local wheel_file
    wheel_file=$(ls wheelhouse/*.whl 2>/dev/null | head -1)
    if [[ -z "${wheel_file}" ]]; then
        wheel_file=$(ls "${OUTPUT_DIR:-/tmp}/artifacts"/scikit_learn-*.whl 2>/dev/null | head -1)
    fi

    if [[ -z "${wheel_file}" ]]; then
        log_warn "No scikit-learn wheel found — artifact will not be created"
    else
        local python_version
        python_version=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

        log_info "Packaging scikit-learn artifact to ${ARTIFACT_DIR} for Python ${python_version}..."
        mkdir -p "${ARTIFACT_DIR}"

        local site_packages="${ARTIFACT_DIR}/lib/python${python_version}/site-packages"
        mkdir -p "${site_packages}"
        python -m pip install --target="${site_packages}" --no-deps "${wheel_file}"

        mkdir -p "${ARTIFACT_DIR}/wheels"
        cp "${wheel_file}" "${ARTIFACT_DIR}/wheels/"

        if [[ -f "COPYING" ]]; then
            cp COPYING "${ARTIFACT_DIR}/LICENSE"
        elif [[ -f "LICENSE" ]]; then
            cp LICENSE "${ARTIFACT_DIR}/LICENSE"
        fi

        cat > "${ARTIFACT_DIR}/env.sh" << 'EOF'
# scikit-learn environment
export SCIKIT_LEARN_PREFIX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_sklearn_python_version="$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")"
export PYTHONPATH="${SCIKIT_LEARN_PREFIX}/lib/python${_sklearn_python_version}/site-packages:${PYTHONPATH:-}"
unset _sklearn_python_version
EOF

        generate_artifact_manifest "${ARTIFACT_DIR}" \
            "scikit-learn" "${PACKAGE_VERSION}" \
            "${PACKAGE_URL}" "${LICENSE_SPDX}" \
            "openblas" "numpy" "scipy"

        log_info "scikit-learn artifact created at ${ARTIFACT_DIR} for Python ${python_version}"
    fi
}

# =============================================================================
# CALLBACK: pre_test — install artifact dependencies and mirror build deps
# =============================================================================
pre_test() {
    log_info "Setting up test environment for scikit-learn..."
    python -m pip install --upgrade pip setuptools wheel

    # Install NumPy and SciPy wheels from artifacts if available
    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    if [[ -n "${NUMPY_PREFIX:-}" ]]; then
        local numpy_wheel
        numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
        if [[ -n "${numpy_wheel}" ]]; then
            log_info "Installing NumPy wheel from artifact into test venv: ${numpy_wheel}"
            python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
        fi
    fi

    if [[ -n "${SCIPY_PREFIX:-}" ]]; then
        local scipy_wheel
        scipy_wheel=$(find "${SCIPY_PREFIX}/wheels" -name "scipy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
        if [[ -n "${scipy_wheel}" ]]; then
            log_info "Installing SciPy wheel from artifact into test venv: ${scipy_wheel}"
            python -m pip install --force-reinstall --no-deps "${scipy_wheel}"
        fi
    fi

    # Mirror build-time dependencies into test venv
    install_pyproject_dependencies
}

# =============================================================================
# CALLBACK: custom_test_command — run scikit-learn validation tests
# =============================================================================
custom_test_command() {
    log_info "Running scikit-learn tests..."

    # Remove plugins that may cause issues
    python -m pip uninstall -y pytest-cov pytest-xdist pytest-codspeed 2>/dev/null || true

    # Avoid import mismatch errors
    export PY_IGNORE_IMPORTMISMATCH=1

    # Basic import and info test
    python -c "import sklearn; print('scikit-learn version:', sklearn.__version__)"

    # Run validation tests
    python -c "
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

print('Testing scikit-learn...')

# Test linear regression
X = np.array([[1], [2], [3], [4], [5]])
y = np.array([2, 4, 6, 8, 10])
model = LinearRegression()
model.fit(X, y)
assert np.allclose(model.predict([[6]]), [12], atol=0.1)

# Test random forest classifier
X = np.random.rand(100, 4)
y = (X[:, 0] + X[:, 1] > 1).astype(int)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
clf = RandomForestClassifier(n_estimators=10, random_state=42)
clf.fit(X_train, y_train)
accuracy = accuracy_score(y_test, clf.predict(X_test))
assert accuracy > 0.5  # Should be better than random

print('scikit-learn basic tests passed!')
"

    log_info "scikit-learn tests passed"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
