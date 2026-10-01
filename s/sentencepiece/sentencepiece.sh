#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sentencepiece
# Version       : 0.2.1
# Source repo   : https://github.com/google/sentencepiece
# Tested on     : UBI 9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts @ibm.com>
#
# Notes:
#   - Tier 0 artifact (no artifact dependencies)
#   - C++ library with Python bindings
#   - Uses bundled protobuf (no external protobuf needed)
#   - Requires cmake build of C++ core before Python install
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sentencepiece"
PACKAGE_VERSION="${1:-0.2.1}"
PACKAGE_URL="https://github.com/google/sentencepiece"

# =============================================================================
# Artifact Declaration (Tier 0 - no artifact dependencies)
# =============================================================================
PROVIDES_ARTIFACT="sentencepiece"
BUILD_WHEEL="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make zlib-devel openssl-devel bzip2-devel libffi-devel python3 python3-devel python3-pip pkg-config gcc-toolset-13-libatomic-devel"
DEB_DEP_PKGS="git gcc g++ cmake make zlib1g-dev libssl-dev libbz2-dev libffi-dev python3-dev python3-pip pkg-config"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make zlib-devel libopenssl-devel libbz2-devel libffi-devel python3-devel python3-pip pkg-config"

# =============================================================================
# Build Configuration
# =============================================================================
LICENSE_SPDX="Apache-2.0"

# =============================================================================
# custom_install: Build C++ library and Python bindings
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}")"

    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}"
        return 0
    fi

    log_info "Building sentencepiece C++ library..."

    mkdir -p build

    # Configure with cmake
    # SPM_ENABLE_TCMALLOC=OFF: avoid gperftools dependency
    # SPM_USE_BUILTIN_PROTOBUF=ON: use bundled protobuf
    cmake -S . -B build \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DSPM_BUILD_TEST=OFF \
        -DSPM_ENABLE_TCMALLOC=OFF \
        -DSPM_USE_BUILTIN_PROTOBUF=ON

    cmake --build build -j"$(nproc)"
    cmake --install build

    mkdir -p "${ARTIFACT_DIR}"

    # Set up environment for Python binding build
    export PATH="${ARTIFACT_DIR}/bin:${PATH}"
    export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:${LD_LIBRARY_PATH:-}"
    export PKG_CONFIG_PATH="${ARTIFACT_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

    log_info "Building Python bindings..."
    
    python -m pip install --upgrade pip setuptools wheel
    python -m pip wheel ./python --no-build-isolation --no-deps -w dist/
    python -m pip install dist/sentencepiece-*.whl

    # Generate env.sh
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}"

    # Append sentencepiece-specific extras
    cat >> "${ARTIFACT_DIR}/env.sh" << EOF

export CMAKE_PREFIX_PATH="${ARTIFACT_DIR}:\${CMAKE_PREFIX_PATH:-}"
EOF


    # Generate manifest
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "${PROVIDES_ARTIFACT}" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "${LICENSE_SPDX}"

    log_info "sentencepiece installed to ${ARTIFACT_DIR}"
}

# =============================================================================
# custom_test_command: Run upstream sentencepiece tests
# =============================================================================
custom_test_command() {
    cd python
    python -m pip install pytest
    python -m pip install . --no-build-isolation
    python -m pytest --import-mode=importlib -o "addopts=" --disable-warnings -v test
    python -c "import sentencepiece; sp = sentencepiece.SentencePieceProcessor(); print('sentencepiece import OK')"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
