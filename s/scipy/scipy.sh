#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : scipy
# Version       : v1.17.1
# Source repo   : https://github.com/scipy/scipy
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="scipy"
PACKAGE_VERSION="${1:-v1.17.1}"
PACKAGE_URL="https://github.com/scipy/scipy"

# =============================================================================
# Artifact dependencies and declaration
# =============================================================================
NUMPY_ARTIFACT_VERSION="${NUMPY_ARTIFACT_VERSION:-v2.2.5}"
BUILD_DEPS=${BUILD_DEPS:-"openblas numpy:${NUMPY_ARTIFACT_VERSION}"}
PROVIDES_ARTIFACT="scipy"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran make cmake ninja-build pkg-config python3 python3-devel python3-pip"
DEB_DEP_PKGS=""   # not yet validated on Debian/Ubuntu
SLES_DEP_PKGS=""  # not yet validated on SUSE

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# CALLBACK: post_clone — apply f2py safe path patch (SciPy issue #24744)
# Needed because meson's `find_program('f2py')` + `f2py -v` probe is fragile
# in this build environment; the patch uses `python -m numpy.f2py` instead.
# This is a build-system logic fix, not a dependency version problem, so a
# version pin cannot replace it. Applies to v1.14+ only; skipped otherwise.
# =============================================================================

post_clone() {
    log_info "Checking whether SciPy f2py safe path patch applies..."

    # Work around SciPy issue #24744 where applicable. Older release lines have
    # different Meson content and do not need this exact patch.
    local f2py_patch="${SCRIPT_DIR}/patches/f2py-safe-path.patch"
    if git apply --check "${f2py_patch}" 2>/dev/null; then
        log_info "Applying f2py safe path patch..."
        git apply "${f2py_patch}"
    else
        log_info "Skipping f2py safe path patch; it is not applicable to ${PACKAGE_VERSION}"
    fi
}

install_scipy_build_dependencies() {
    log_info "Preparing SciPy build dependency installation..."

    local req_file
    req_file="$(mktemp)"
    log_info "Writing SciPy pyproject build requirements to temporary file: ${req_file}"

    log_info "Installing tomli for pyproject.toml parsing"
    python -m pip install tomli
    log_info "Reading SciPy build-system requirements from pyproject.toml"
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
        log_info "Installing SciPy build dependencies from pyproject.toml"
        python -m pip install -r "${req_file}"
    else
        log_warn "No build-system requirements found; using fallback build dependencies"
        python -m pip install \
            "meson>=1.5.0" \
            ninja \
            "meson-python>=0.15.0,<0.19.0" \
            "Cython>=3.0.8,<3.2.0" \
            "pybind11>=2.13.2,<2.14.0" \
            "pythran>=0.14.0,<0.19.0"
    fi

    rm -f "${req_file}"
    log_info "Installing additional SciPy build tooling"
    python -m pip install ninja pyproject-metadata packaging "patchelf>=0.11.0"
}

# =============================================================================
# CALLBACK: pre_build — set up openblas/numpy artifacts and build deps
# =============================================================================

pre_build() {
    log_info "Configuring scipy build environment..."

    # C++ template depth for scipy's heavy template usage
    log_info "Setting C++ template depth required by SciPy's generated C++ sources"
    export CXXFLAGS="${CXXFLAGS:-} -ftemplate-depth=2000"

    # Set NumPy artifact prefix before configuring build dependencies.
    local numpy_artifact_dir
    numpy_artifact_dir="$(artifact_dir "numpy" "${NUMPY_ARTIFACT_VERSION}")"
    log_info "Checking required NumPy artifact: ${numpy_artifact_dir}"
    if [[ ! -f "${numpy_artifact_dir}/env.sh" ]]; then
        log_error "Required NumPy artifact is missing: ${numpy_artifact_dir}/env.sh"
        log_error "Expected build order: openblas -> numpy:${NUMPY_ARTIFACT_VERSION} -> scipy:${PACKAGE_VERSION}"
        false
    fi
    log_info "Sourcing NumPy artifact environment from ${numpy_artifact_dir}/env.sh"
    source "${numpy_artifact_dir}/env.sh"

    # Configure to use openblas from artifact
    if [[ -n "${OPENBLAS_PREFIX:-}" ]]; then
        log_info "Using OpenBLAS from artifact: ${OPENBLAS_PREFIX}"
        log_info "Exporting OpenBLAS include, library, pkg-config, and CMake paths for Meson"
        export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
        export LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${LIBRARY_PATH:-}"
        export CPATH="${OPENBLAS_PREFIX}/include:${CPATH:-}"
        export PKG_CONFIG_PATH="${OPENBLAS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
        export CMAKE_PREFIX_PATH="${OPENBLAS_PREFIX}:${CMAKE_PREFIX_PATH:-}"
        export OpenBLAS_HOME="${OPENBLAS_PREFIX}"
    else
        log_warn "OPENBLAS_PREFIX not set - scipy will use fallback BLAS"
    fi

    # NumPy from the artifact keeps scipy builds aligned with downstream packages
    # such as onnxruntime and avoids pip resolving a newer source build.
    if [[ -z "${NUMPY_PREFIX:-}" || ! -d "${NUMPY_PREFIX}" ]]; then
        log_error "NumPy artifact is required but NUMPY_PREFIX is invalid: ${NUMPY_PREFIX:-<unset>}"
        false
    fi
    log_info "Using NumPy from artifact: ${NUMPY_PREFIX}"

    # Prefer the artifact wheel that matches the active Python ABI, such as
    # cp311 or cp312, because NumPy contains compiled extension modules that
    # are not portable across Python minor versions.
    local numpy_wheel
    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
    log_info "Looking for NumPy artifact wheel matching Python ABI ${python_abi}"
    numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    if [[ -z "${numpy_wheel}" ]]; then
        log_warn "NumPy ${python_abi} wheel was not found under ${NUMPY_PREFIX}/wheels; using artifact PYTHONPATH"
        log_info "Verifying NumPy is importable from the sourced artifact environment"
        if ! python -c "import numpy; print('NumPy version:', numpy.__version__)" ; then
            log_error "NumPy artifact is not importable from ${NUMPY_PREFIX}"
            false
        fi
    else
        log_info "Installing NumPy wheel from artifact: ${numpy_wheel}"
        python -m pip install --force-reinstall --no-deps "${numpy_wheel}"

        local numpy_artifact_site
        numpy_artifact_site="${NUMPY_PREFIX}/lib/python$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")/site-packages"
        log_info "Removing artifact site-packages from PYTHONPATH after wheel install: ${numpy_artifact_site}"
        while [[ "${PYTHONPATH:-}" == "${numpy_artifact_site}" || "${PYTHONPATH:-}" == "${numpy_artifact_site}:"* ]]; do
            if [[ "${PYTHONPATH}" == "${numpy_artifact_site}" ]]; then
                unset PYTHONPATH
                break
            fi
            export PYTHONPATH="${PYTHONPATH#${numpy_artifact_site}:}"
        done
        python -c "import numpy; print('NumPy import path:', numpy.__file__)"
    fi

    install_scipy_build_dependencies

}

# =============================================================================
# CALLBACK: pre_test — install artifact NumPy into the isolated .venv-test
# =============================================================================

pre_test() {
    log_info "Installing artifact NumPy into test venv (.venv-test does not inherit .venv-build)"
    local python_abi numpy_wheel
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
    numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    if [[ -n "${numpy_wheel}" ]]; then
        log_info "Installing NumPy wheel from artifact into test venv: ${numpy_wheel}"
        python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
    fi
}

# =============================================================================
# CALLBACK: post_build — package scipy artifact (env.sh + wheels/) for consumers
# Mirrors the pattern used by numpy.sh post_build.
# =============================================================================
post_build() {
    log_info "Packaging SciPy artifact..."

    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "scipy" "${PACKAGE_VERSION}")"

    local wheel_file
    wheel_file=$(ls wheelhouse/*.whl 2>/dev/null | head -1)
    if [[ -z "${wheel_file}" ]]; then
        wheel_file=$(ls "${OUTPUT_DIR:-/tmp}/artifacts"/scipy-*.whl 2>/dev/null | head -1)
    fi

    if [[ -z "${wheel_file}" ]]; then
        log_warn "No SciPy wheel found — artifact will not be created"
    else
        local python_version
        python_version=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

        log_info "Packaging SciPy artifact to ${ARTIFACT_DIR} for Python ${python_version}..."
        mkdir -p "${ARTIFACT_DIR}"

        local site_packages="${ARTIFACT_DIR}/lib/python${python_version}/site-packages"
        mkdir -p "${site_packages}"
        python -m pip install --target="${site_packages}" --no-deps "${wheel_file}"

        mkdir -p "${ARTIFACT_DIR}/wheels"
        cp "${wheel_file}" "${ARTIFACT_DIR}/wheels/"

        if [[ -f "LICENSE.txt" ]]; then
            cp LICENSE.txt "${ARTIFACT_DIR}/LICENSE"
        elif [[ -f "LICENSE" ]]; then
            cp LICENSE "${ARTIFACT_DIR}/LICENSE"
        fi

        cat > "${ARTIFACT_DIR}/env.sh" << 'EOF'
# SciPy environment
export SCIPY_PREFIX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_scipy_python_version="$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")"
export PYTHONPATH="${SCIPY_PREFIX}/lib/python${_scipy_python_version}/site-packages:${PYTHONPATH:-}"
unset _scipy_python_version
EOF

        generate_artifact_manifest "${ARTIFACT_DIR}" \
            "scipy" "${PACKAGE_VERSION}" \
            "${PACKAGE_URL}" "${LICENSE_SPDX}" \
            "openblas" "numpy"

        log_info "SciPy artifact created at ${ARTIFACT_DIR} for Python ${python_version}"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — run scipy smoke tests to verify install
# Replaces the template pytest cascade on purpose: the full SciPy suite is far
# too heavy for CI, and its tests live in nested dirs (scipy/*/tests) that the
# template's default discovery does not pick up.
# =============================================================================

custom_test_command() {
    log_info "Running scipy smoke tests..."

    local smoke_dir
    smoke_dir="$(mktemp -d)"
    log_info "Running SciPy smoke tests from an isolated directory: ${smoke_dir}"
    (
        trap 'popd >/dev/null; rm -rf "${smoke_dir}"' EXIT
        pushd "${smoke_dir}" >/dev/null
        python - <<'PY'
import numpy as np
import scipy
from scipy import linalg, optimize, special

print("NumPy version:", np.__version__)
print("NumPy path:", np.__file__)
print("SciPy version:", scipy.__version__)
print("SciPy path:", scipy.__file__)

a = np.array([[4.0, 1.0], [1.0, 3.0]])
chol = linalg.cholesky(a, lower=True)
assert chol.shape == (2, 2)
assert np.allclose(chol @ chol.T, a)

assert np.isclose(special.expit(0.0), 0.5)

result = optimize.minimize(lambda x: (x[0] - 2.0) ** 2, np.array([0.0]))
assert result.success
assert np.allclose(result.x, [2.0], atol=1e-4)

print("SciPy smoke tests passed")
PY
    )
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
