#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : onnxruntime
# Version       : v1.22.0
# Source repo   : https://github.com/microsoft/onnxruntime
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="onnxruntime"
PACKAGE_VERSION="${1:-v1.22.0}"
PACKAGE_URL="https://github.com/microsoft/onnxruntime"

# =============================================================================
# Artifact dependencies and declaration
# =============================================================================
BUILD_DEPS=${BUILD_DEPS:-"openblas numpy:v2.2.5 protobuf:v25.3 abseil-cpp:20240722.0"}
PROVIDES_ARTIFACT="onnxruntime"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran make cmake ninja-build python3 python3-devel python3-pip patch wget bzip2-devel libevent-devel libffi-devel libtool openssl-devel xz zlib-devel"
DEB_DEP_PKGS="git gcc g++ gfortran make cmake ninja-build python3-dev python3-pip patch wget"
SLES_DEP_PKGS="git gcc gcc-c++ gcc-fortran make cmake ninja python3-devel python3-pip patch wget"

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="MIT"

# =============================================================================
# CALLBACK: post_clone — sync and initialize submodules, patch eigen deps.txt
# =============================================================================
post_clone() {
    log_info "Initializing onnxruntime submodules..."
    # git submodule sync + update are called explicitly here (instead of relying
    # on init_submodules) because the eigen patching logic below requires all
    # submodules to be present before cmake/deps.txt can be inspected.
    git submodule sync
    git submodule update --init --recursive

    # eigen.patch contains alternative hunks for two different source commits.
    # Select only the matching section; preserve checksum verification and reject
    # unexpected dependency entries. Repeated runs accept an applied patch.
    #
    # Skip patching entirely if the eigen line already uses the correct post-patch
    # content (e.g. v1.22.x already ships the GitHub mirror URL + fixed checksum
    # upstream, so the patch is both unnecessary and offset-wrong for that version).
    local eigen_line eigen_commit eigen_patch
    eigen_line=$(grep '^eigen;' cmake/deps.txt)
    eigen_commit=$(sed -n 's|^eigen;.*/archive/\([0-9a-f]*\)/.*|\1|p' cmake/deps.txt)
    eigen_patch=$(awk -v commit="$eigen_commit" '
        /^# Eigen commit: / { selected = ($4 == commit); next }
        selected { print }
    ' "${SCRIPT_DIR}/eigen.patch")
    if [[ -n "$eigen_patch" ]]; then
        # Extract the expected -line (original) and +line (replacement) from the
        # patch hunk. Use a direct sed substitution instead of git apply so that
        # the fix is completely independent of line-number offsets in deps.txt.
        local orig_line patched_line
        orig_line=$(grep '^-eigen;' <<< "$eigen_patch" | sed 's/^-//')
        patched_line=$(grep '^+eigen;' <<< "$eigen_patch" | sed 's/^+//')
        if [[ "$eigen_line" == "$patched_line" ]]; then
            log_info "Eigen entry already matches patched content, skipping"
        elif [[ "$eigen_line" == "$orig_line" ]]; then
            sed -i "s|^eigen;.*|${patched_line}|" cmake/deps.txt
            log_info "Eigen entry updated in cmake/deps.txt"
        else
            log_error "Unexpected Eigen dependency line for ${PACKAGE_VERSION}: ${eigen_line}"
            false
        fi
    elif [[ "${PACKAGE_VERSION#v}" == "1.21.0" ]]; then
        log_error "Unexpected Eigen dependency for ONNX Runtime v1.21.0"
        false
    fi
}

# =============================================================================
# CALLBACK: pre_build — configure artifact environment for cmake/ninja build
# =============================================================================
pre_build() {
    log_info "Configuring onnxruntime build environment..."

    # Configure to use openblas from artifact
    if [[ -n "${OPENBLAS_PREFIX:-}" ]]; then
        log_info "Using OpenBLAS from artifact: ${OPENBLAS_PREFIX}"
        export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
        export PKG_CONFIG_PATH="${OPENBLAS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
    fi

    # Configure protobuf from artifact
    if [[ -z "${PROTOBUF_PREFIX:-}" ]]; then
        log_error "Protobuf artifact is required but PROTOBUF_PREFIX is not set"
        report_dependency_fail
    fi

    log_info "Using Protobuf from artifact: ${PROTOBUF_PREFIX}"
    export PROTOC="${PROTOBUF_PREFIX}/bin/protoc"
    if [[ -f "${PROTOBUF_PREFIX}/lib64/libprotobuf.so" ]]; then
        export PROTOBUF_LIBRARY="${PROTOBUF_PREFIX}/lib64/libprotobuf.so"
    elif [[ -f "${PROTOBUF_PREFIX}/lib/libprotobuf.so" ]]; then
        export PROTOBUF_LIBRARY="${PROTOBUF_PREFIX}/lib/libprotobuf.so"
    else
        log_error "libprotobuf.so not found under ${PROTOBUF_PREFIX}/lib64 or ${PROTOBUF_PREFIX}/lib"
        report_dependency_fail
    fi
    export LD_LIBRARY_PATH="${PROTOBUF_PREFIX}/lib64:${PROTOBUF_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
    export LIBRARY_PATH="${PROTOBUF_PREFIX}/lib64:${PROTOBUF_PREFIX}/lib:${LIBRARY_PATH:-}"
    export CPATH="${PROTOBUF_PREFIX}/include:${CPATH:-}"
    export CMAKE_PREFIX_PATH="${PROTOBUF_PREFIX}:${CMAKE_PREFIX_PATH:-}"

    # Configure abseil-cpp from artifact
    if [[ -n "${ABSEIL_CPP_PREFIX:-}" ]]; then
        log_info "Using Abseil-cpp from artifact: ${ABSEIL_CPP_PREFIX}"
        export LD_LIBRARY_PATH="${ABSEIL_CPP_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
        export CMAKE_PREFIX_PATH="${ABSEIL_CPP_PREFIX}:${CMAKE_PREFIX_PATH:-}"
    fi

    # numpy from artifact
    if [[ -z "${NUMPY_PREFIX:-}" ]]; then
        log_error "NumPy artifact is required but NUMPY_PREFIX is not set"
        report_dependency_fail
    fi
    log_info "Using NumPy from artifact: ${NUMPY_PREFIX}"

    log_info "Installing Python build dependencies"
    python -m pip install packaging wheel pybind11 cython setuptools ninja cmake auditwheel patchelf

    # NumPy's artifact env.sh adds the site-packages directory matching the
    # running Python minor version to PYTHONPATH. Consume that artifact directly
    # instead of reinstalling its wheel or falling back to PyPI.
    local NUMPY_INCLUDE
    if ! NUMPY_INCLUDE=$(python -c "import numpy; print(numpy.get_include())"); then
        log_error "NumPy artifact at ${NUMPY_PREFIX} is not usable with $(python --version 2>&1)"
        report_dependency_fail
    fi
    if [[ -z "${NUMPY_INCLUDE}" ]]; then
        log_error "NumPy include path could not be determined"
        report_dependency_fail
    fi
    export Python3_NumPy_INCLUDE_DIR="${NUMPY_INCLUDE}"
    export CXXFLAGS="-I${NUMPY_INCLUDE} ${CXXFLAGS:-}"

    # Suppress some warnings
    export CXXFLAGS="${CXXFLAGS} -Wno-stringop-overflow"
    export CFLAGS="${CFLAGS:-} -Wno-stringop-overflow"
}

# =============================================================================
# CALLBACK: custom_install — build onnxruntime using its own build.sh script
# =============================================================================
custom_install() {
    log_info "Building onnxruntime with build.sh..."

    local NUMPY_INCLUDE
    NUMPY_INCLUDE=$(python -c "import numpy; print(numpy.get_include())")
    if [[ -z "${NUMPY_INCLUDE}" ]]; then
        log_error "NumPy include path could not be determined"
        report_build_fail
    fi

    # Build using onnxruntime's build script
    if ! ./build.sh \
        --cmake_extra_defines \
            "onnxruntime_PREFER_SYSTEM_LIB=ON" \
            "onnxruntime_BUILD_UNIT_TESTS=OFF" \
            "onnxruntime_RUN_ONNX_TESTS=OFF" \
            "Protobuf_PROTOC_EXECUTABLE=${PROTOC}" \
            "Protobuf_INCLUDE_DIR=${PROTOBUF_PREFIX}/include" \
            "Protobuf_LIBRARY=${PROTOBUF_LIBRARY}" \
            "Python3_NumPy_INCLUDE_DIR=${NUMPY_INCLUDE}" \
            "CMAKE_CXX_STANDARD=17" \
            "CMAKE_POLICY_VERSION_MINIMUM=3.5" \
        --cmake_generator Ninja \
        --build_shared_lib \
        --config Release \
        --update \
        --build \
        --skip_submodule_sync \
        --allow_running_as_root \
        --compile_no_warning_as_error \
        --skip_tests \
        --build_wheel; then
        report_build_fail
    fi

    local wheel
    wheel=$(find build/Linux/Release/dist -name '*.whl' -print 2>/dev/null | head -1)
    if [[ -z "${wheel}" ]]; then
        log_error "onnxruntime wheel was not produced under build/Linux/Release/dist"
        report_wheel_fail
    fi

    mkdir -p dist wheelhouse
    if auditwheel repair "${wheel}" -w wheelhouse/; then
        wheel=$(find wheelhouse -name '*.whl' -print 2>/dev/null | head -1)
    fi

    if [[ -z "${wheel}" ]]; then
        log_error "onnxruntime wheel was not available after build/repair"
        report_wheel_fail
    fi

    # Copy wheel to dist/ and OUTPUT_DIR/artifacts for package artifacts.
    cp "${wheel}" dist/
    if [[ -n "${OUTPUT_DIR:-}" ]]; then
        mkdir -p "${OUTPUT_DIR}/artifacts"
        cp "${wheel}" "${OUTPUT_DIR}/artifacts/"
    fi

    python -m pip install --force-reinstall "${wheel}"

    log_info "Running onnxruntime validation..."
    # Validate outside the source checkout so it cannot shadow the installed wheel.
    # Preserve Powercore's Python path configuration, which Python -I would discard.
    if ! (cd /tmp && python -c "import onnxruntime; print('ONNX Runtime version:', onnxruntime.__version__)"); then
        report_test_fail
    fi

    if ! (cd /tmp && python -c "
import numpy as np
import onnxruntime as ort

print('ONNX Runtime version:', ort.__version__)
print('Available providers:', ort.get_available_providers())
print('ONNX Runtime basic import test passed!')
"); then
        report_test_fail
    fi

    log_info "onnxruntime validation passed"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
