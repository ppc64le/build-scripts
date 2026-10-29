#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : xgboost-cpu
# Version       : v3.1.3
# Source repo   : https://github.com/dmlc/xgboost
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM <ppc64le@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="xgboost-cpu"
PACKAGE_VERSION="${1:-v3.1.3}"
PACKAGE_URL="https://github.com/dmlc/xgboost"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git cmake gcc gcc-c++ gcc-gfortran openssl-devel openblas-devel python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Artifact dependencies
# =============================================================================
BUILD_DEPS=${BUILD_DEPS:-"numpy:v2.2.5 scipy"}

# =============================================================================
# CALLBACK: post_clone — patch ppc64le platform tag and strip GPU-only deps
# =============================================================================
post_clone() {
    log_info "Applying ppc64le-specific patches for CPU-only build..."

    # Fix platform tag generation for ppc64le wheels
    if [[ -f "python-package/hatch_build.py" ]]; then
        log_info "Patching hatch_build.py for ppc64le platform tag..."
        sed -i '/^from hatchling\.builders\.hooks\.plugin\.interface import BuildHookInterface/a import sysconfig' python-package/hatch_build.py
        sed -i 's/next(platform_tags())/sysconfig.get_platform().replace("-", "_").replace(".", "_")/g' python-package/hatch_build.py
    fi

    # Remove GPU-only dependencies from pyproject.toml
    if [[ -f "python-package/pyproject.toml" ]]; then
        log_info "Removing GPU-only dependencies (nvidia-nccl-cu12) from pyproject.toml..."
        sed -i '/nvidia-nccl-cu12/d' python-package/pyproject.toml

        # Ensure wheel build target is configured
        if ! grep -q '^\[tool.hatch.build.targets.wheel\]' python-package/pyproject.toml; then
            printf '\n[tool.hatch.build.targets.wheel]\npackages = ["xgboost/"]\n' >> python-package/pyproject.toml
        fi
    fi
}

# =============================================================================
# CALLBACK: custom_install — CMake CPU-only C++ build then Python package build
# xgboost requires the C++ shared library to be present before the Python wheel
# can be assembled. DUSE_CUDA=OFF ensures no CUDA dependency on ppc64le.
# =============================================================================
custom_install() {
    local SRC_DIR
    SRC_DIR="$(pwd)"

    # -------------------------------------------------------------------------
    # Step 1: Build xgboost C++ library (CPU-only) with CMake
    # -------------------------------------------------------------------------
    log_info "Configuring xgboost C++ build (CPU-only)..."
    mkdir -p build
    cd build

    cmake .. \
        -DUSE_CUDA=OFF \
        -DUSE_NCCL=OFF \
        -DUSE_OPENMP=ON \
        -DCMAKE_BUILD_TYPE=Release

    log_info "Compiling xgboost C++ library..."
    make -j"$(nproc)"

    cd "${SRC_DIR}"

    if [[ ! -f "lib/libxgboost.so" ]]; then
        log_error "libxgboost.so not found after C++ build"
        false
    fi
    log_info "C++ library built successfully: lib/libxgboost.so"

    # -------------------------------------------------------------------------
    # Step 2: Build the Python wheel from python-package/
    # The template already created and activated .venv-build at the repo root;
    # we reuse that venv rather than creating a second one inside python-package/.
    # -------------------------------------------------------------------------
    log_info "Installing Python build dependencies into active venv..."
    python -m pip install --upgrade pip setuptools wheel build hatchling
    python -m pip install packaging pathspec pluggy

    log_info "Installing numpy and scipy from artifacts..."
    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
    local numpy_wheel
    numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" 2>/dev/null | head -1)
    if [[ -n "${numpy_wheel}" ]]; then
        python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
    else
        log_warn "No numpy wheel for ${python_abi} found in artifact — using artifact PYTHONPATH"
    fi
    local scipy_wheel=""
    if [[ -n "${SCIPY_PREFIX:-}" ]]; then
        scipy_wheel=$(find "${SCIPY_PREFIX}/wheels" -name "scipy-*-${python_abi}-${python_abi}-*.whl" 2>/dev/null | head -1)
    fi
    if [[ -n "${scipy_wheel}" ]]; then
        python -m pip install --force-reinstall --no-deps "${scipy_wheel}"
    else
        log_warn "No scipy wheel for ${python_abi} found in artifact — falling back to pip"
        python -m pip install scipy
    fi

    log_info "Building xgboost Python wheel..."
    cd python-package
    python -m build

    # Copy the wheel to the repo-root dist/ so the template's test phase
    # can locate it via `ls dist/*.whl` and install it into .venv-test.
    if ls dist/*.whl 1>/dev/null 2>&1; then
        mkdir -p "${SRC_DIR}/dist"
        cp dist/*.whl "${SRC_DIR}/dist/"
        log_info "Installing built wheel into build venv..."
        python -m pip install dist/*.whl
        log_info "Verifying xgboost import..."
        python -c "import xgboost; print('xgboost version:', xgboost.__version__)"
    else
        log_error "No wheel files found in python-package/dist/"
        cd "${SRC_DIR}"
        false
    fi

    cd "${SRC_DIR}"
}

# =============================================================================
# CALLBACK: pre_test — install numpy and scipy into the test venv
# =============================================================================
pre_test() {
    log_info "Installing numpy and scipy into test venv..."
    python -m pip install --upgrade pip setuptools wheel
    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
    local numpy_wheel
    numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" 2>/dev/null | head -1)
    if [[ -n "${numpy_wheel}" ]]; then
        python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
    else
        log_warn "No numpy wheel for ${python_abi} found in artifact — falling back to pip"
        python -m pip install numpy
    fi
    local scipy_wheel=""
    if [[ -n "${SCIPY_PREFIX:-}" ]]; then
        scipy_wheel=$(find "${SCIPY_PREFIX}/wheels" -name "scipy-*-${python_abi}-${python_abi}-*.whl" 2>/dev/null | head -1)
    fi
    if [[ -n "${scipy_wheel}" ]]; then
        python -m pip install --force-reinstall --no-deps "${scipy_wheel}"
    else
        log_warn "No scipy wheel for ${python_abi} found in artifact — falling back to pip"
        python -m pip install scipy
    fi
}

# =============================================================================
# CALLBACK: custom_test_command — CPU-only smoke test and basic training
# Full pytest suite requires additional GPU-free test configuration;
# running a functional smoke test here to validate the CPU build.
# =============================================================================
custom_test_command() {
    log_info "Running xgboost CPU smoke test..."

    python -c "
import xgboost as xgb
import numpy as np

# Verify no CUDA device is required
print('xgboost version:', xgb.__version__)

# Basic DMatrix and training test
X = np.array([[1, 2], [3, 4], [5, 6], [7, 8]], dtype=float)
y = np.array([0, 1, 0, 1], dtype=float)

dtrain = xgb.DMatrix(X, label=y)
print('DMatrix created with', dtrain.num_row(), 'rows')

params = {
    'max_depth': 2,
    'eta': 0.1,
    'objective': 'binary:logistic',
    'tree_method': 'hist',
    'device': 'cpu',
}
bst = xgb.train(params, dtrain, num_boost_round=5)

preds = bst.predict(dtrain)
print('Predictions:', preds)
print('xgboost CPU smoke test PASSED')
"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
