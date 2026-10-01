#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : zfp
# Version       : 1.0.1
# Source repo   : https://github.com/LLNL/zfp
# Tested on     : UBI:9.6
# Language      : C, Python
# Script License: Apache License 2.0
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Notes:
#   - zfp is a C/C++ floating-point compression library with Python bindings
#   - Build requires CMake to compile shared C library before Python install
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="zfp"
PACKAGE_VERSION="${1:-1.0.1}"
PACKAGE_URL="https://github.com/LLNL/zfp"

# =============================================================================
# Artifact Declaration (Tier 0 - no dependencies)
# =============================================================================
PROVIDES_ARTIFACT="zfp"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make cmake openssl-devel python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ make cmake libssl-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ make cmake libopenssl-devel python3-devel python3-pip"

BUILD_WHEEL="true"

# =============================================================================
# CALLBACK: custom_install
# CMake-based build workflow - C library must be built before Python bindings
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}"
        return 0
    fi

    # Install numpy and cython in the active venv
    log_info "Installing cython and numpy..."
    local lang_ver=(${LANGUAGE_VERSION//./ })
    if [[ "${PACKAGE_VERSION}" == "1.0.0" ]]; then
        log_info "ZFP 1.0.0: Pinning numpy<2, using latest cython for Python 3.13 compatibility"
        python -m pip install cython "numpy<2"
    else
        if [[ ${lang_ver[0]} -gt 3 ]] || [[ ${lang_ver[0]} -eq 3 && ${lang_ver[1]} -ge 12 ]]; then
            log_info "Python >= 3.12, installing numpy 2.x"
            python -m pip install cython "numpy>=2.0"
        else
            log_info "Python < 3.12, installing numpy 1.x"
            python -m pip install "cython==0.29.36" "numpy>=1.23,<2.0"
        fi
    fi

    NUMPY_INCLUDE_DIR=$(python -c "import numpy; print(numpy.get_include())")

    # Create CMake build directory for native library
    log_info "Building native zfp library..."
    mkdir -p build
    cd build

    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_ZFPY=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DPYTHON_EXECUTABLE="$(which python)" \
        -DPYTHON_INCLUDE_DIR="$(python -c "import sysconfig; print(sysconfig.get_path('include'))")" \
        -DPYTHON_LIBRARY="$(python -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))")" \
        -DNUMPY_INCLUDE_DIR="$NUMPY_INCLUDE_DIR" \
        -DCMAKE_C_FLAGS="-fopenmp" \
        -DCMAKE_CXX_FLAGS="-fopenmp" \
        -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++ -fopenmp" || { log_error "CMake configuration failed"; return 1; }

    make -j"$(nproc)" || { log_error "Build failed"; return 1; }
    make install || { log_error "Install failed"; return 1; }

    export CMAKE_PREFIX_PATH="${ARTIFACT_DIR}"
    cd ..

    # Patch setup.py 
    log_info "Patching setup.py..."
    if [[ -f "setup.py" ]]; then
        sed -i 's/), language_level = "3"]/)]/' setup.py
    fi

    # Export LDFLAGS and LD_LIBRARY_PATH globally so the subsequent wheel build can link and repair successfully
    export LDFLAGS="-L${ARTIFACT_DIR}/lib ${LDFLAGS:-}"
    export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${LD_LIBRARY_PATH:-}"

    # Get python major/minor version directory (e.g., python3.13)
    local py_ver_dir="python${lang_ver[0]}.${lang_ver[1]}"

    # Standard post-build cleanup, license copying, and env.sh generation
    _cleanup_artifact "${ARTIFACT_DIR}"
    _copy_license "${ARTIFACT_DIR}"
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}"
    echo "export PYTHONPATH=\"\${ZFP_PREFIX}/lib/${py_ver_dir}/site-packages:\${PYTHONPATH:-}\"" >> "${ARTIFACT_DIR}/env.sh"

    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}"

    # Verify zfpy installation (run inside the active virtual environment)
    log_info "Verifying zfpy installation..."
    local site_packages="${ARTIFACT_DIR}/lib/${py_ver_dir}/site-packages"
    if PYTHONPATH="${site_packages}:${PYTHONPATH:-}" LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${LD_LIBRARY_PATH:-}" python -c "import zfpy; print('zfpy imported successfully')"; then
        log_info "zfpy import successful"
    else
        log_error "zfpy import failed"
        return 1
    fi
}

# =============================================================================
# CALLBACK: pre_test
# Runs inside the test virtual environment (.venv-test) before package build/install.
# =============================================================================
pre_test() {
    log_info "Installing cython and numpy for testing..."
    if [[ "${PACKAGE_VERSION}" == "1.0.0" ]]; then
        log_info "ZFP 1.0.0: Pinning numpy<2 for compatibility, using latest cython"
        pip install setuptools wheel cython "numpy<2"
    else
        log_info "ZFP >= 1.0.1: Installing numpy and cython"
        local lang_ver=(${LANGUAGE_VERSION//./ })
        if [[ ${lang_ver[0]} -gt 3 ]] || [[ ${lang_ver[0]} -eq 3 && ${lang_ver[1]} -ge 12 ]]; then
            pip install setuptools wheel cython "numpy>=2.0"
        else
            pip install setuptools wheel "cython==0.29.36" "numpy>=1.23,<2.0"
        fi
    fi
}

# =============================================================================
# CALLBACK: custom_test_command
# Runs in test virtual environment (.venv-test).
# =============================================================================
custom_test_command() {
    log_info "Creating dynamic zfpy integration test..."
    cat > test_zfpy.py << 'EOF'
import numpy as np
import zfpy

# Create a sample array
arr = np.linspace(0.0, 1.0, 1000).reshape((10, 10, 10))

# Compress
compressed = zfpy.compress_numpy(arr, tolerance=1e-5)

# Decompress
decompressed = zfpy.decompress_numpy(compressed)

# Assert similarity
assert np.allclose(arr, decompressed, atol=1e-5)
print("zfpy test passed successfully!")
EOF

    log_info "Running zfpy tests..."
    python test_zfpy.py
}

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="BSD-3-Clause"

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
