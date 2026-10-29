#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : faiss-cpu
# Version       : 1.9.0.post1
# Source repo   : https://github.com/faiss-wheels/faiss-wheels
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Varsha Kumar <varsha.kumar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="faiss-cpu"
PACKAGE_VERSION="${1:-1.9.0.post1}"
PACKAGE_URL="https://github.com/faiss-wheels/faiss-wheels"

# =============================================================================
# Artifact Declaration (Tier 1 - depends on openblas system package)
# =============================================================================
PROVIDES_ARTIFACT="faiss-cpu"

# scipy is only needed by app.py at test time; consumed from the scipy artifact
SCIPY_ARTIFACT_VERSION="${SCIPY_ARTIFACT_VERSION:-v1.17.0}"
BUILD_DEPS=${BUILD_DEPS:-"scipy:${SCIPY_ARTIFACT_VERSION}"}

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake automake autoconf openblas-devel python3 python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ cmake automake autoconf libopenblas-dev python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ cmake automake autoconf openblas-devel python3 python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_clone — clone main branch, not the v1.9.0.post1 tag
# =============================================================================
# IMPORTANT: The v1.9.0.post1 tag uses the OLD setuptools backend (requires
# system swig + separate manual cmake build). The main branch uses
# scikit-build-core which handles cmake+swig internally via uv build.
# The v1 (UBI10) script did: git clone --recursive (no checkout = main HEAD)
# then stamped PACKAGE_VERSION into pyproject.toml. We replicate that here
# by temporarily redirecting PACKAGE_VERSION to "main" for the clone step,
# then restoring the real version in post_clone for the sed patches.
pre_clone() {
    log_info "Redirecting checkout to main branch (scikit-build-core backend)"
    _FAISS_REAL_VERSION="${PACKAGE_VERSION}"
    PACKAGE_VERSION="main"
    return 0
}

# =============================================================================
# CALLBACK: post_clone — configure uv environment and version
# =============================================================================
post_clone() {
    # Restore the real version and strip any leading 'v'
    PACKAGE_VERSION="${_FAISS_REAL_VERSION#v}"
    log_info "Restored PACKAGE_VERSION: ${PACKAGE_VERSION}"

    log_info "Configuring uv environment for Python version compatibility"

    # Allow detected Python version in uv's environment filter
    echo -e "\n[tool.uv]\nenvironments = [\"python_version == '3.11' or python_version == '3.12' or python_version == '3.13' or python_version == '3.14'\"]" >> pyproject.toml

    # Stamp version into pyproject.toml
    sed -i '/^\[project\]/,/^$/ {s/version = "[^"]*"/version = "'"${PACKAGE_VERSION}"'"/}' pyproject.toml

    # Stamp version into submodule setup.py — path depends on branch:
    # main (scikit-build-core era): third-party/faiss/faiss/python/setup.py
    if [ -f "third-party/faiss/faiss/python/setup.py" ]; then
        log_info "Patching third-party submodule setup.py version"
        sed -i "s/.version=.*/version='${PACKAGE_VERSION}',/" third-party/faiss/faiss/python/setup.py
    fi
}

# =============================================================================
# CALLBACK: custom_install — build faiss C++ library and package wheel via uv
# =============================================================================
custom_install() {
    log_info "Installing uv build tool"
    python3 -m pip install --upgrade uv

    # Pin uv to the active Python version
    PY_MAJOR_MINOR=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    log_info "Pinning uv to Python version: ${PY_MAJOR_MINOR}"
    uv python pin "${PY_MAJOR_MINOR}"

    # Detect the active Python version tag for wheel building
    CP=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('py_version_nodot'))")
    log_info "Building wheel for Python cp${CP}"

    export INDEX_URL_DEVPY="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"

    # uv build invokes scikit-build-core which runs cmake+ninja+swig internally.
    log_info "Building wheel with uv (scikit-build-core handles cmake+swig internally)"
    uv build --wheel --config-setting "wheel.py-api=cp${CP}" \
        --extra-index-url "${INDEX_URL_DEVPY}"
}

# =============================================================================
# CALLBACK: post_build — copy wheel into the artifact directory
# =============================================================================
post_build() {
    log_info "Packaging faiss-cpu wheel into artifact directory..."

    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    # Find the repaired wheel (written to OUTPUT_DIR by _process_and_package_wheels)
    local wheel_file
    wheel_file=$(ls "${OUTPUT_DIR:-/output}"/faiss_cpu-*.whl 2>/dev/null | head -1)
    if [[ -z "${wheel_file}" ]]; then
        wheel_file=$(ls wheelhouse/faiss_cpu-*.whl 2>/dev/null | head -1)
    fi
    if [[ -z "${wheel_file}" ]]; then
        wheel_file=$(ls dist/faiss_cpu-*.whl 2>/dev/null | head -1)
    fi

    if [[ -n "${wheel_file}" ]]; then
        log_info "Copying faiss-cpu wheel to artifact: ${ARTIFACT_DIR}/wheels/"
        mkdir -p "${ARTIFACT_DIR}/wheels"
        cp "${wheel_file}" "${ARTIFACT_DIR}/wheels/"
        log_info "faiss-cpu artifact wheel saved: $(basename "${wheel_file}")"
    else
        log_warn "No faiss-cpu wheel found to copy into artifact — skipping wheels/ dir"
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — run custom test file with dependencies
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies"
    export INDEX_URL_DEVPY="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"

    # Locate the SciPy artifact. scipy.sh post_build stores its wheel at
    local scipy_artifact_dir="" _v
    for _v in "${SCIPY_ARTIFACT_VERSION}" "${SCIPY_ARTIFACT_VERSION#v}"; do
        if [[ -d "$(artifact_dir "scipy" "${_v}")/wheels" ]]; then
            scipy_artifact_dir="$(artifact_dir "scipy" "${_v}")"
            break
        fi
    done
    if [[ -z "${scipy_artifact_dir}" ]]; then
        log_error "Required SciPy artifact is missing: $(artifact_dir "scipy" "${SCIPY_ARTIFACT_VERSION}")/wheels"
        log_error "Expected build order: openblas -> numpy -> scipy:${SCIPY_ARTIFACT_VERSION} -> faiss-cpu"
        return 1
    fi
    export SCIPY_PREFIX="${scipy_artifact_dir}"
    log_info "Using SciPy from artifact: ${SCIPY_PREFIX}"

    # Pick the wheel matching the active Python ABI (cp311, cp312, ...) 
    local python_abi scipy_wheel
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
    scipy_wheel=$(find "${SCIPY_PREFIX}/wheels" -name "scipy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    if [[ -z "${scipy_wheel}" ]]; then
        log_error "No SciPy ${python_abi} wheel found under ${SCIPY_PREFIX}/wheels"
        return 1
    fi
    log_info "Installing SciPy wheel from artifact: ${scipy_wheel}"
    python -m pip install --force-reinstall --no-deps "${scipy_wheel}"

    python -m pip install sentence-transformers \
        --extra-index-url "${INDEX_URL_DEVPY}"

    # Resolve app.py path for different execution contexts
    if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -n "${CURRENT_DIR:-}" ]; then
        TEST_PATH="$(cd "${CURRENT_DIR}" && cd "$(dirname "${BUILD_SCRIPT_PATH}")" && pwd)/app.py"
    else
        TEST_PATH="${SCRIPT_DIR}/app.py"
    fi

    if [ ! -f "${TEST_PATH}" ]; then
        log_error "Test file not found at ${TEST_PATH}"
        return 1
    fi

    log_info "Running test file: ${TEST_PATH}"
    python "${TEST_PATH}"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
