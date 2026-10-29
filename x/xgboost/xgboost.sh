#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : xgboost
# Version       : v3.1.3
# Source repo   : https://github.com/dmlc/xgboost
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - xgboost requires a CMake-based C++ build before the Python package
#   - On ppc64le, OpenBLAS is built from source for optimal performance
#   - The python-package subdirectory contains the actual Python module
#   - Container environment provides: cmake, gcc/g++, gcc-gfortran
#   - Repository is pre-cloned with full history (submodules initialized)
#
# Complexity: Level 4 (custom_install required)
#   - CMake-based C++ build prerequisite
#   - OpenBLAS build from source (ppc64le)
#   - Custom pyproject.toml modifications
#   - Non-standard package location (python-package/)
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="xgboost"
PACKAGE_VERSION="${1:-v3.1.3}"
PACKAGE_URL="https://github.com/dmlc/xgboost"


PROVIDES_ARTIFACT="xgboost"


# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building xgboost
# Note: cmake, gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git cmake gcc gcc-c++ gcc-gfortran openssl-devel openblas-devel python3 python3-devel python3-pip"
DEB_DEP_PKGS="git cmake gcc g++ gfortran libssl-dev libopenblas-dev python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git cmake gcc gcc-c++ gcc-fortran libopenssl-devel openblas-devel python3 python3-devel python3-pip"

# =============================================================================
# OPTIONAL: Skip tests flag - xgboost tests require additional setup
# Set to "false" to enable tests (requires pytest, scipy, etc.)
# =============================================================================
SKIP_TESTS="${SKIP_TESTS:-true}"

# =============================================================================
# CALLBACK: post_clone
# Apply ppc64le patches (submodules initialized by template)
# =============================================================================
post_clone() {
    log_info "Applying ppc64le-specific patches..."
    # Fix platform tag generation for ppc64le wheels
    if [[ -f "python-package/hatch_build.py" ]]; then
        # Add sysconfig import for platform tag workaround
        sed -i '/^from hatchling\.builders\.hooks\.plugin\.interface import BuildHookInterface/a import sysconfig' python-package/hatch_build.py
        # Use sysconfig platform instead of platform_tags() which may fail on ppc64le
        sed -i 's/next(platform_tags())/sysconfig.get_platform().replace("-", "_").replace(".", "_")/g' python-package/hatch_build.py
    fi

    # Remove nvidia-nccl-cu12 dependency (not required for CPU-only build)
    if [[ -f "python-package/pyproject.toml" ]]; then
        log_info "Removing nvidia-nccl-cu12 dependency from pyproject.toml..."
        sed -i '/nvidia-nccl-cu12/d' python-package/pyproject.toml

        # Add wheel build configuration if not present
        if ! grep -q '^\[tool.hatch.build.targets.wheel\]' python-package/pyproject.toml; then
            echo -e '\n[tool.hatch.build.targets.wheel]\npackages = ["xgboost/"]' >> python-package/pyproject.toml
        fi
    fi
}

# =============================================================================
# CALLBACK: custom_install
# xgboost requires building C++ library first, then Python package
# =============================================================================
custom_install() {
    local SRC_DIR=$(pwd)
    local XGBOOST_ARTIFACT_DIR="${OUTPUT_DIR:-/tmp}/artifacts/xgboost"

    # Create output directories
    mkdir -p "${XGBOOST_ARTIFACT_DIR}/lib" "${XGBOOST_ARTIFACT_DIR}/include/xgboost" "${XGBOOST_ARTIFACT_DIR}/bin"

    # -------------------------------------------------------------------------
    # Step 1: Build xgboost C++ library with CMake
    # -------------------------------------------------------------------------
    log_info "Building xgboost C++ library..."
    mkdir -p build
    cd build

    if ! cmake -DCMAKE_INSTALL_PREFIX="${XGBOOST_ARTIFACT_DIR}" ..; then
        log_error "CMake configuration failed"
        return 1
    fi

    if ! make -j$(nproc); then
        log_error "C++ build failed"
        return 1
    fi

    # Copy built artifacts
    if [[ -f "${SRC_DIR}/lib/libxgboost.so" ]]; then
        cp "${SRC_DIR}/lib/libxgboost.so" "${XGBOOST_ARTIFACT_DIR}/lib/"
    else
        log_error "libxgboost.so not found after build"
        return 1
    fi

    cp -Rf "${SRC_DIR}/include/xgboost" "${XGBOOST_ARTIFACT_DIR}/include/"

    # Copy rabit headers only for xgboost < 3.0.0
    local version_num="${PACKAGE_VERSION#v}"
    local version_less_than_3=$(printf '%s\n3.0.0' "${version_num}" | sort -V | head -n1)
    if [[ "$version_less_than_3" != "3.0.0" ]]; then
        log_info "Copying rabit headers (xgboost < 3.0.0)..."
        cp -Rf "${SRC_DIR}/rabit/include/rabit" "${XGBOOST_ARTIFACT_DIR}/include/xgboost/"
    fi

    if [[ -d "${SRC_DIR}/src/c_api" ]]; then
        cp -f "${SRC_DIR}/src/c_api/"*.h "${XGBOOST_ARTIFACT_DIR}/include/xgboost/" 2>/dev/null || true
    fi

    # Create env.sh for artifact reuse
    cat > "${XGBOOST_ARTIFACT_DIR}/env.sh" << EOF
export LD_LIBRARY_PATH="${XGBOOST_ARTIFACT_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export CMAKE_PREFIX_PATH="${XGBOOST_ARTIFACT_DIR}:\${CMAKE_PREFIX_PATH:-}"
export CPATH="${XGBOOST_ARTIFACT_DIR}/include:\${CPATH:-}"
EOF
    log_info "Created ${XGBOOST_ARTIFACT_DIR}/env.sh for artifact reuse"

    cd "${SRC_DIR}"

    # -------------------------------------------------------------------------
    # Step 2: Build Python package
    # -------------------------------------------------------------------------
    log_info "Building xgboost Python package..."
    cd python-package

    python3 -m venv .venv-build
    source .venv-build/bin/activate

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

    if ! python -m build; then
        log_error "Python package build failed"
        deactivate
        return 1
    fi

    # Install the built wheel
    if ls dist/*.whl 1>/dev/null 2>&1; then
        pip install dist/*.whl
        log_info "Package installed successfully"

        # Verify import
        if python -c "import xgboost; print(f'xgboost version: {xgboost.__version__}')"; then
            log_info "Import verification passed"
        else
            log_warn "Import verification failed, but wheel was built"
        fi
    else
        log_error "No wheel files found in dist/"
        deactivate
        return 1
    fi

    deactivate
    cd "${SRC_DIR}"

    return 0
}

# =============================================================================
# CALLBACK: custom_test_command
# Run basic import test (full pytest suite requires additional dependencies)
# =============================================================================
custom_test_command() {
    log_info "Running xgboost import test..."

    # Basic functionality test
    python -c "
import xgboost as xgb
import numpy as np

# Create simple test data
X = np.array([[1, 2], [3, 4], [5, 6], [7, 8]])
y = np.array([0, 1, 0, 1])

# Test DMatrix creation
dtrain = xgb.DMatrix(X, label=y)
print(f'DMatrix created with {dtrain.num_row()} rows')

# Test basic training
param = {'max_depth': 2, 'eta': 0.1, 'objective': 'binary:logistic'}
bst = xgb.train(param, dtrain, num_boost_round=2)
print('Basic training test passed')

print('xgboost import and basic functionality test PASSED')
"
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
