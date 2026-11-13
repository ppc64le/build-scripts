#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : xformers
# Version       : v0.0.29
# Source repo   : https://github.com/facebookresearch/xformers
# Tested on     : UBI:9.6
# Language      : Python, C++
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="xformers"
PACKAGE_VERSION="${1:-v0.0.29}"
PACKAGE_URL="https://github.com/facebookresearch/xformers"
PROVIDES_ARTIFACT="xformers"

# =============================================================================
# Artifact dependencies
# =============================================================================
BUILD_DEPS=${BUILD_DEPS:-"openblas:v0.3.32 pytorch:v2.7.1 libprotobuf:v26.1 abseil-cpp:20240116.2 numpy:v2.2.5 scipy:v1.17.1"}

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc-toolset-13 ninja-build rust cargo python3-devel python3-pip jq pkg-config atlas"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="BSD-3-Clause"


install_pytorch() {
    local python_abi pytorch_wheel=""
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")


    log_info "Looking for PyTorch artifact wheel matching Python ABI ${python_abi}"
    if [[ -n "${PYTORCH_PREFIX:-}" ]]; then
        pytorch_wheel=$(find "${PYTORCH_PREFIX}" -name "torch-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    fi

    if [[ -z "${pytorch_wheel}" ]]; then
        log_warn "No PyTorch ${python_abi} wheel found in artifact (PYTORCH_PREFIX=${PYTORCH_PREFIX:-<unset>}) — configuring artifact paths"
        # pytorch env.sh already put the artifact site-packages on PYTHONPATH
        log_info "Verifying PyTorch is importable from the sourced artifact environment"
        if ! python -c "import torch; print('PyTorch version:', torch.__version__)"; then
            log_error "PyTorch artifact is not importable from ${PYTORCH_PREFIX:-<unset>}"
        fi
    else
        log_info "Installing PyTorch wheel from artifact: ${pytorch_wheel}"
        python -m pip install --force-reinstall  --no-deps "${pytorch_wheel}"

        local pytorch_artifact_site
        pytorch_artifact_site="${PYTORCH_PREFIX}/lib/python$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")/site-packages"
        log_info "Removing artifact site-packages from PYTHONPATH after wheel install: ${pytorch_artifact_site}"
        while [[ "${PYTHONPATH:-}" == "${pytorch_artifact_site}" || "${PYTHONPATH:-}" == "${pytorch_artifact_site}:"* ]]; do
            if [[ "${PYTHONPATH}" == "${pytorch_artifact_site}" ]]; then
                unset PYTHONPATH
                break
            fi
            export PYTHONPATH="${PYTHONPATH#${pytorch_artifact_site}:}"
        done
        python -c "import torch; print('PyTorch import path:', torch.__file__)"
    fi
}

# =============================================================================
# HELPER: install SciPy from the scipy artifact wheel
# requirements-test.txt asks for scipy; without this pip compiles it from source
# on ppc64le, and the parallel C++ jobs get OOM-killed (cc1plus: Killed).
# =============================================================================
install_scipy() {
    local python_abi scipy_wheel=""
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    log_info "Looking for SciPy artifact wheel matching Python ABI ${python_abi}"
    if [[ -n "${SCIPY_PREFIX:-}" ]]; then
        scipy_wheel=$(find "${SCIPY_PREFIX}" -name "scipy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    fi

    if [[ -z "${scipy_wheel}" ]]; then
        log_warn "No SciPy ${python_abi} wheel found in artifact (SCIPY_PREFIX=${SCIPY_PREFIX:-<unset>}) — falling back to artifact PYTHONPATH"
        if ! python -c "import scipy; print('SciPy version:', scipy.__version__)"; then
            log_error "SciPy artifact is not importable from ${SCIPY_PREFIX:-<unset>}"
        fi
    else
        log_info "Installing SciPy wheel from artifact: ${scipy_wheel}"
        python -m pip install --force-reinstall --no-deps "${scipy_wheel}"

        local scipy_artifact_site
        scipy_artifact_site="${SCIPY_PREFIX}/lib/python$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")/site-packages"
        log_info "Removing artifact site-packages from PYTHONPATH after wheel install: ${scipy_artifact_site}"
        while [[ "${PYTHONPATH:-}" == "${scipy_artifact_site}" || "${PYTHONPATH:-}" == "${scipy_artifact_site}:"* ]]; do
            if [[ "${PYTHONPATH}" == "${scipy_artifact_site}" ]]; then
                unset PYTHONPATH
                break
            fi
            export PYTHONPATH="${PYTHONPATH#${scipy_artifact_site}:}"
        done
        python -c "import scipy; print('SciPy import path:', scipy.__file__)"
    fi
}

# =============================================================================
# HELPER: install NumPy from the numpy artifact wheel
# The test venv is isolated; installing the artifact wheel avoids pip fetching
# or compiling numpy on ppc64le.
# =============================================================================
install_numpy() {
    local python_abi numpy_wheel=""
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    log_info "Looking for NumPy artifact wheel matching Python ABI ${python_abi}"
    if [[ -n "${NUMPY_PREFIX:-}" ]]; then
        numpy_wheel=$(find "${NUMPY_PREFIX}" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    fi

    if [[ -z "${numpy_wheel}" ]]; then
        log_warn "No NumPy ${python_abi} wheel found in artifact (NUMPY_PREFIX=${NUMPY_PREFIX:-<unset>}) — falling back to artifact PYTHONPATH"
        if ! python -c "import numpy; print('NumPy version:', numpy.__version__)"; then
            log_error "NumPy artifact is not importable from ${NUMPY_PREFIX:-<unset>}"
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
}



# =============================================================================
# CALLBACK: post_clone — initialize submodules and set version.txt
# =============================================================================
post_clone() {
    
    local VERSION_NUM="${PACKAGE_VERSION#v}"
    log_info "Setting version.txt to $VERSION_NUM"
    if ! echo "$VERSION_NUM" > version.txt; then
        log_error "Failed to write version.txt"
    fi

    # Remove outdated pytest-mpi which fails building from source on Python 3.12+
    if [[ -f "requirements-test.txt" ]]; then
        log_info "Removing incompatible pytest-mpi from requirements-test.txt"
        sed -i '/pytest-mpi/d' requirements-test.txt
    fi
}

# =============================================================================
# CALLBACK: pre_build — configure build environment
# =============================================================================
pre_build() {
    log_info "Configuring build environment"

    # The libprotobuf, abseil-cpp and pytorch env.sh files (sourced via BUILD_DEPS) already
    # export their paths. The openblas artifact has no env.sh, so wire it up here.
    local openblas_prefix="${OPENBLAS_PREFIX:-$(artifact_dir openblas v0.3.32)}"
    if [[ -d "${openblas_prefix}" ]]; then
        log_info "Using OpenBLAS from artifact: ${openblas_prefix}"
        export OPENBLAS_PREFIX="${openblas_prefix}"
        export OpenBLAS_HOME="${openblas_prefix}"
        export LD_LIBRARY_PATH="${openblas_prefix}/lib:${LD_LIBRARY_PATH:-}"
        export LIBRARY_PATH="${openblas_prefix}/lib:${LIBRARY_PATH:-}"
        export CPATH="${openblas_prefix}/include:${CPATH:-}"
        export PKG_CONFIG_PATH="${openblas_prefix}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
        export CMAKE_PREFIX_PATH="${openblas_prefix}:${CMAKE_PREFIX_PATH:-}"
    else
        log_warn "OpenBLAS artifact not found at ${openblas_prefix}"
    fi

    python -m pip install --upgrade pip wheel
    python -m pip install ninja 'cmake<4' hydra-core

    install_pytorch

    export _GLIBCXX_USE_CXX11_ABI=1
    export BUILD_VERSION="${PACKAGE_VERSION#v}"
    export CXXFLAGS="-Wno-unused-variable -Wno-unused-parameter"
    local _nproc
    _nproc=$(nproc 2>/dev/null || echo 4)
    local jobs=$(( _nproc > 4 ? 4 : _nproc ))

    export MAX_JOBS=${jobs}
    export CPU_COUNT=${jobs}
    export MAKEFLAGS="-j${jobs}"
    export CMAKE_BUILD_PARALLEL_LEVEL=${jobs}
    log_info "Configured build concurrency: MAX_JOBS=${MAX_JOBS} (host reports ${_nproc} cores)"

    log_info "Build environment configured"
}

# =============================================================================
# CALLBACK: post_build — package xformers artifact (env.sh + wheels/) for consumers
# Mirrors the pattern used by pytorch.sh post_build.
# =============================================================================
post_build() {
    log_info "Packaging xformers artifact..."

    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir xformers "${PACKAGE_VERSION}")"

    local wheel_file
    wheel_file=$(ls dist/*.whl 2>/dev/null | head -1)

    if [[ -z "${wheel_file}" ]]; then
        log_warn "No xformers wheel found in dist/ — artifact will not be created"
        return
    fi

    local python_version
    python_version=$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

    log_info "Packaging xformers artifact to ${ARTIFACT_DIR} for Python ${python_version}..."
    mkdir -p "${ARTIFACT_DIR}"

    local site_packages="${ARTIFACT_DIR}/lib/python${python_version}/site-packages"
    mkdir -p "${site_packages}"
    python -m pip install --target="${site_packages}" --no-deps "${wheel_file}"

    mkdir -p "${ARTIFACT_DIR}/wheels"
    cp "${wheel_file}" "${ARTIFACT_DIR}/wheels/"

    if [[ -f "LICENSE" ]]; then
        cp LICENSE "${ARTIFACT_DIR}/LICENSE"
    fi

    cat > "${ARTIFACT_DIR}/env.sh" << 'EOF'
# xformers environment
export XFORMERS_PREFIX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_xformers_python_version="$(python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null || python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")"
export PYTHONPATH="${XFORMERS_PREFIX}/lib/python${_xformers_python_version}/site-packages:${PYTHONPATH:-}"
unset _xformers_python_version
EOF

    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "xformers" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "BSD-3-Clause" \
        "openblas" "pytorch" "libprotobuf" "abseil-cpp"

    log_info "xformers artifact created at ${ARTIFACT_DIR} for Python ${python_version}"
}

# =============================================================================
# CALLBACK: pre_test — prepare test environment
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
        # torch runtime dependencies (the torch wheel is installed with --no-deps)
    python -m pip install  filelock typing_extensions "sympy==1.13.1" jinja2 networkx fsspec mpmath pyyaml


    python -m pip install --upgrade pip wheel
    python -m pip install 'pytest==8.2.2' hydra-core

    # install NumPy from the artifact
    install_numpy

    #install PyTorch from the artifact again
    install_pytorch

    # Install SciPy from the artifact so requirements-test.txt does not build it from source
    install_scipy
}

# =============================================================================
# CALLBACK: custom_test_command — run specific tests with ignores
# =============================================================================
custom_test_command() {
    log_info "Running xformers tests with specific ignores"

    export PY_IGNORE_IMPORTMISMATCH=1

    python -m pytest tests/ \
        --ignore=tests/test_custom_ops.py \
        --ignore=tests/test_sparsecs.py \
        --ignore=tests/test_mem_eff_attention.py \
        --ignore=tests/test_core_attention.py \
        --ignore=tests/test_sparse_tensors.py \
        --ignore=tests/test_checkpoint.py
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"