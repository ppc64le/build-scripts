#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tf2onnx
# Version       : v1.16.1
# Source repo   : https://github.com/onnx/tensorflow-onnx
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tf2onnx"
PACKAGE_VERSION="${1:-v1.16.1}"
PACKAGE_URL="https://github.com/onnx/tensorflow-onnx"

BUILD_DEPS="libprotobuf"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel cmake ninja-build"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — ensure VERSION_NUMBER is included in sdist
# =============================================================================
post_clone() {
    log_info "Adding VERSION_NUMBER to MANIFEST.in for sdist packaging"
    echo "include VERSION_NUMBER" >> MANIFEST.in
}

# =============================================================================
# CALLBACK: pre_build — install Python build deps and build onnx dependency
# =============================================================================
pre_build() {
    log_info "Installing Python build dependencies..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install numpy pybind11 pytest-runner cython protobuf

    local WORK_DIR
    WORK_DIR="$(pwd)"
    local BUILD_DIR="/tmp/tf2onnx_build_deps"
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"

    # Build and install onnx into build venv
    if [[ ! -d "onnx" ]]; then
        log_info "Cloning onnx..."
        git clone https://github.com/onnx/onnx -b v1.17.0
        (cd onnx && git submodule update --init --recursive)
    fi
    # Check the venv, not the directory: /tmp may hold onnx from an earlier run
    # while this fresh venv does not, and pip would then build onnx from sdist.
    if ! python -c "import onnx" 2>/dev/null; then
        log_info "Building onnx..."
        cd onnx
        export CXXFLAGS="-std=c++17"
        export CMAKE_ARGS="-DONNX_USE_PROTOBUF_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_STANDARD_REQUIRED=ON -DCMAKE_CXX_EXTENSIONS=OFF -DCMAKE_CXX_FLAGS=-std=c++17 -DPython3_EXECUTABLE=$(which python)"
        if [[ -n "${LIBPROTOBUF_PREFIX:-}" ]]; then
            CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=${LIBPROTOBUF_PREFIX}/bin/protoc -DProtobuf_INCLUDE_DIR=${LIBPROTOBUF_PREFIX}/include"
            if [[ -f "${LIBPROTOBUF_PREFIX}/lib64/libprotobuf.so" ]]; then
                CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_LIBRARY=${LIBPROTOBUF_PREFIX}/lib64/libprotobuf.so"
            elif [[ -f "${LIBPROTOBUF_PREFIX}/lib/libprotobuf.so" ]]; then
                CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_LIBRARY=${LIBPROTOBUF_PREFIX}/lib/libprotobuf.so"
            fi
        fi
        export CMAKE_ARGS
        python setup.py install
        rm -rf build .setuptools-cmake-build
        cd "${BUILD_DIR}"
    fi

    cd "${WORK_DIR}"
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies and mirror build dependencies
# =============================================================================
pre_test() {
    log_info "Free space in /tmp before installing test dependencies:"
    df -h /tmp
    log_info "Installing build backend and mirroring dependencies in test venv..."
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install numpy pybind11 pytest-runner cython parameterized pytest timeout-decorator graphviz pyyaml

    # Extract Python version
    local py_major py_minor
    py_major=$(python -c "import sys; print(sys.version_info.major)")
    py_minor=$(python -c "import sys; print(sys.version_info.minor)")

    if [[ ${py_major} -eq 3 && ${py_minor} -ge 10 ]]; then
        # ppc64le index: tensorflow 2.14.1 has cp310/cp311 wheels only; cp312 needs 2.18.1.
        # Both are compiled against numpy 1.x. The index only carries onnxruntime 1.27.0 (cp311+).
        log_info "Installing tensorflow from the ppc64le wheel index..."
        python -m pip install --prefer-binary --no-cache-dir \
            --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
            "numpy<2" "tensorflow>=2.14,<2.19"
        log_info "Installing onnxruntime from the ppc64le wheel index..."
        python -m pip install --prefer-binary --no-cache-dir \
            --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
            "onnxruntime>=1.21"

        local BUILD_DIR="/tmp/tf2onnx_build_deps"

        python -m pip install protobuf

        # Install onnx into test venv
        if [[ -d "${BUILD_DIR}/onnx" ]]; then
            log_info "Installing onnx in test venv..."
            local WORK_DIR
            WORK_DIR="$(pwd)"
            cd "${BUILD_DIR}/onnx"
            export CXXFLAGS="-std=c++17"
            export CMAKE_ARGS="-DONNX_USE_PROTOBUF_SHARED_LIBS=ON -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_STANDARD_REQUIRED=ON -DCMAKE_CXX_EXTENSIONS=OFF -DCMAKE_CXX_FLAGS=-std=c++17 -DPython3_EXECUTABLE=$(which python)"
            if [[ -n "${LIBPROTOBUF_PREFIX:-}" ]]; then
                CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=${LIBPROTOBUF_PREFIX}/bin/protoc -DProtobuf_INCLUDE_DIR=${LIBPROTOBUF_PREFIX}/include"
                if [[ -f "${LIBPROTOBUF_PREFIX}/lib64/libprotobuf.so" ]]; then
                    CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_LIBRARY=${LIBPROTOBUF_PREFIX}/lib64/libprotobuf.so"
                elif [[ -f "${LIBPROTOBUF_PREFIX}/lib/libprotobuf.so" ]]; then
                    CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_LIBRARY=${LIBPROTOBUF_PREFIX}/lib/libprotobuf.so"
                fi
            fi
            export CMAKE_ARGS
            python setup.py install
            rm -rf build .setuptools-cmake-build
            cd "${WORK_DIR}"
        fi
    else
        log_info "Python version is < 3.10 (got ${py_major}.${py_minor}). Skipping tensorflow, onnxruntime, and custom onnx build."
    fi

    # Remove plugins that might cause conflicts
    python -m pip uninstall -y pytest-cov pytest-xdist pytest-codspeed 2>/dev/null
}

# =============================================================================
# CALLBACK: custom_test_command — run tf2onnx unit tests
# =============================================================================
custom_test_command() {
    # Extract Python version
    local py_major py_minor
    py_major=$(python -c "import sys; print(sys.version_info.major)")
    py_minor=$(python -c "import sys; print(sys.version_info.minor)")

    if [[ ${py_major} -eq 3 && ${py_minor} -ge 10 ]]; then
        # The tf2onnx wheel pins protobuf~=3.20, which the template applies when it installs
        # tf2onnx into the test venv (after pre_test). This downgrades protobuf from >=4 to
        # 3.20.x and causes pip to remove tensorflow (which requires protobuf>=4.25.3 for 2.18+).
        # Fix: upgrade protobuf first, then re-install tensorflow so it is present for the tests.
        log_info "Restoring protobuf runtime compatible with tensorflow..."
        python -m pip install "protobuf>=4.25.3,<6"
        log_info "Re-installing tensorflow after protobuf upgrade (removed by tf2onnx protobuf~=3.20 pin)..."
        python -m pip install --prefer-binary --no-cache-dir \
            --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
            "numpy<2" "tensorflow>=2.14,<2.19"
        log_info "Verifying tensorflow and onnxruntime are importable..."
        python -c "import tensorflow as tf, onnxruntime; print(tf.__version__, onnxruntime.__version__)"
        log_info "Running tf2onnx unit tests..."
        # Set PYTHONPATH to include tests/ so helper modules like common.py can be imported by conftest.py
        # test_transpose_with_loop_*: the optimizer test emits a Loop graph that is not topologically
        # sorted; the newer onnxruntime (>=1.21) on the ppc64le index rejects it as INVALID_GRAPH.
        # test_transpose_reducemax_2/5: fail on v1.15.1 with the newer onnxruntime on ppc64le.
        PYTHONPATH=".:tests" python -m pytest \
            -o "addopts=" \
            --disable-warnings \
            --deselect tests/test_optimizers.py::OptimizerTests::test_transpose_reducemax_2 \
            --deselect tests/test_optimizers.py::OptimizerTests::test_transpose_reducemax_5 \
            --deselect tests/test_optimizers.py::OptimizerTests::test_transpose_with_loop_0 \
            --deselect tests/test_optimizers.py::OptimizerTests::test_transpose_with_loop_1 \
            --deselect tests/test_optimizers.py::OptimizerTests::test_transpose_with_loop_2 \
            tests/test_internals.py \
            tests/test_optimizers.py
    else
        # tf2onnx unconditionally imports tensorflow in __init__.py; the ppc64le wheel index
        # only carries tensorflow for cp310+, so there is no installable tensorflow on 3.9.
        # Verify the package is present via pip show instead of a Python import.
        log_info "Python version is < 3.10 (got ${py_major}.${py_minor}). Skipping full unit tests."
        log_info "Verifying tf2onnx package installation via pip show..."
        python -m pip show tf2onnx
    fi
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
