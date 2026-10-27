#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : Paddle
# Version       : v3.0.0
# Source repo   : https://github.com/PaddlePaddle/Paddle
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Prerna Kumbhar <Prerna.Kumbhar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="paddle"
PACKAGE_VERSION="${1:-v3.0.0}"

PACKAGE_URL="https://github.com/PaddlePaddle/Paddle"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
# patchelf is not available in UBI9 repos — installed via pip in custom_install
# libtiff-devel and freetype-devel are already present on UBI:9.6 base image
RH_DEP_PKGS="git wget cmake make gcc gcc-c++ gcc-gfortran patch \
    python3-devel openblas-devel zlib-devel libjpeg-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_clone — disable GPU/Intel-only submodules before recursive clone
#
# third_party/openvino pulls ARM ComputeLibrary, libxsmm, open_model_zoo and
# dozens of other Intel/GPU submodules (multi-GB, unused on ppc64le CPU builds).
# third_party/flashattn is CUDA-only and nests 5 copies of cutlass.
# Disabling them in global git config prevents --recurse-submodules from
# fetching them, avoiding disk exhaustion during clone.
# =============================================================================
pre_clone() {
    log_info "Disabling GPU/Intel-only submodules to prevent disk exhaustion"
    git config --global submodule."third_party/openvino".active  false
    git config --global submodule."third_party/flashattn".active false
    git config --global submodule."third_party/cccl".active      false
    git config --global submodule."third_party/cub".active       false
    git config --global submodule."third_party/jitify".active    false
    git config --global submodule."third_party/onednn".active    false
    git config --global submodule."third_party/cutlass".active   false
}

# =============================================================================
# CALLBACK: post_clone — deinit any heavy submodules that were checked out and
# apply the ppc64le compatibility patch
# =============================================================================
post_clone() {
    log_info "Removing GPU/Intel-only submodule content to reclaim disk space"
    for mod in openvino flashattn cccl cub jitify onednn cutlass; do
        git submodule deinit -f "third_party/${mod}" 2>/dev/null
        rm -rf "third_party/${mod}"
    done

    log_info "Applying Paddle ppc64le patch for ${PACKAGE_VERSION}"
    git apply "${SCRIPT_DIR}/patches/paddle_v3.0.0.patch"
}

# =============================================================================
# CALLBACK: custom_install — install deps, cmake+make, stage wheel for template
#
# The template creates and activates .venv-build before calling this callback,
# so no venv setup or deactivate is needed here.
# The built wheel is copied to dist/ so the template's test phase can pick it
# up automatically (lines 546-555 of python.sh install dist/*.whl into .venv-test).
# Uses Release build type and -DWITH_TESTING=OFF to skip test binary compilation,
# significantly reducing both peak RAM and disk usage.
# Parallelism is capped at 8 jobs to prevent OOM from concurrent cc1plus
# processes (each can consume 1-3 GB RAM on heavily-templated C++).
# Build tree is removed after staging — compiled artefacts are no longer needed.
# =============================================================================
custom_install() {
    log_info "Installing build dependencies"
    python -m pip install --upgrade pip wheel
    # patchelf not in UBI9 repos — install via pip
    python -m pip install patchelf numpy protobuf scikit-learn
    python -m pip install -r python/requirements.txt

    log_info "Configuring Paddle with cmake (CPU-only, no AVX, no tests)"
    mkdir -p build
    cd build
    cmake \
        -DCMAKE_CXX_FLAGS="-Wno-stringop-overflow -Wno-error=overloaded-virtual" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_EXE_LINKER_FLAGS="-Wl,--reduce-memory-overheads" \
        -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--reduce-memory-overheads" \
        -DWITH_GPU=OFF \
        -DWITH_AVX=OFF \
        -DWITH_TESTING=OFF \
        ..

    log_info "Building Paddle (capped at 8 parallel jobs to limit peak RAM)"
    make -j$(( $(nproc) < 8 ? $(nproc) : 8 ))
    cd ..

    log_info "Staging wheel for template test phase"
    mkdir -p dist
    cp build/python/dist/paddlepaddle*.whl dist/

    log_info "Removing build artefacts to reclaim disk space"
    rm -rf build/
}

# =============================================================================
# CALLBACK: custom_test_command — import smoke-test (full test suite not run on
# ppc64le; the build itself validates correctness).
# The template installs the wheel into .venv-test before calling this callback,
# so paddle is already importable in the active venv — no manual venv sourcing needed.
# =============================================================================
custom_test_command() {
    log_info "Running Paddle import smoke-test"
    python -c "import paddle; print('paddle version:', paddle.__version__)"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
