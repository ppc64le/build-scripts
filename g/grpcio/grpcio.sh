#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : grpcio
# Version       : v1.68.0
# Source repo   : https://github.com/grpc/grpc
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Sanket-Kumbhar <Sanket.Kumbhar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="grpc"
PACKAGE_VERSION="${1:-v1.68.0}"
PACKAGE_URL="https://github.com/grpc/grpc"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel openssl-devel gcc-c++"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

BUILD_DEPS=${BUILD_DEPS:-"re2 abseil-cpp protobuf c-ares zlib"}
PROVIDES_ARTIFACT="grpcio"


# =============================================================================
# CALLBACK: pre_build — set environment variables and install Cython
# =============================================================================
pre_build() {
    log_info "Setting grpc build environment variables"
    export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
    export GRPC_PYTHON_BUILD_WITH_CYTHON=1
    # Limit parallel C++ compile workers to match container CPU quota (up to 4)
    local jobs=$(( $(nproc) > 4 ? 4 : $(nproc) ))
    export GRPC_PYTHON_BUILD_EXT_COMPILER_JOBS="${jobs}"

    # Build CFLAGS and LDFLAGS incrementally so each artifact can contribute
    local extra_cflags="-std=c++17 -fvisibility=hidden -fno-wrapv -fno-exceptions"
    local extra_ldflags="-lpthread -static-libgcc"
    # Append -latomic if the linker needs it (ppc64le often does)
    if c++ -x c++ -std=c++14 - -latomic </dev/null 2>/dev/null; then
        extra_ldflags="${extra_ldflags} -latomic"
    fi

    # --- re2 artifact ---
    if [[ -n "${RE2_PREFIX}" ]]; then
        log_info "Using system re2 from artifact: ${RE2_PREFIX}"
        export GRPC_PYTHON_BUILD_SYSTEM_RE2=1
        # setup.py hardcodes RE2_INCLUDE to /usr/include/re2 when SYSTEM_RE2=1;
        # override via CFLAGS so the compiler finds our artifact headers.
        extra_cflags="${extra_cflags} -I${RE2_PREFIX}/include"
        extra_ldflags="${extra_ldflags} -L${RE2_PREFIX}/lib -lre2"
    else
        log_info "RE2_PREFIX unset — using vendored third_party/re2"
    fi

    # --- c-ares artifact ---
    # GRPC_PYTHON_BUILD_SYSTEM_CARES=1 drops third_party/cares sources and adds
    # -lcares to EXTENSION_LIBRARIES. setup.py hardcodes CARES_INCLUDE=/usr/include
    # when set; our artifact headers are injected via GRPC_PYTHON_CFLAGS instead.
    if [[ -n "${C_ARES_PREFIX}" ]]; then
        log_info "Using system c-ares from artifact: ${C_ARES_PREFIX}"
        export GRPC_PYTHON_BUILD_SYSTEM_CARES=1
        extra_cflags="${extra_cflags} -I${C_ARES_PREFIX}/include"
        extra_ldflags="${extra_ldflags} -L${C_ARES_PREFIX}/lib -lcares"
    else
        log_info "C_ARES_PREFIX unset — using vendored third_party/cares"
    fi

    # --- abseil-cpp artifact ---
    if [[ -n "${ABSEIL_CPP_PREFIX}" ]]; then
        log_info "Using system abseil-cpp from artifact: ${ABSEIL_CPP_PREFIX}"
        export GRPC_PYTHON_BUILD_SYSTEM_ABSL=1
        # setup.py hardcodes ABSL_INCLUDE to /usr/include when SYSTEM_ABSL=1;
        # override via CFLAGS so the compiler finds our artifact headers.
        extra_cflags="${extra_cflags} -I${ABSEIL_CPP_PREFIX}/include"
        # Link all absl shared libs found in the artifact
        local absl_ldflags=""
        absl_ldflags="-L${ABSEIL_CPP_PREFIX}/lib $(ls "${ABSEIL_CPP_PREFIX}/lib/"libabsl_*.so 2>/dev/null | \
            xargs -I{} basename {} .so | sed 's/^lib/-l/' | tr '\n' ' ')"
        extra_ldflags="${extra_ldflags} ${absl_ldflags}"
    else
        log_info "ABSEIL_CPP_PREFIX unset — using vendored third_party/abseil-cpp"
    fi

    # --- zlib artifact ---
    if [[ -n "${ZLIB_PREFIX}" ]]; then
        log_info "Using system zlib from artifact: ${ZLIB_PREFIX}"
        export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
        extra_cflags="${extra_cflags} -I${ZLIB_PREFIX}/include"
        extra_ldflags="${extra_ldflags} -L${ZLIB_PREFIX}/lib -lz"
    else
        log_info "ZLIB_PREFIX unset — using vendored third_party/zlib"
    fi

    export GRPC_PYTHON_CFLAGS="${extra_cflags}"
    export GRPC_PYTHON_LDFLAGS="${extra_ldflags}"
    log_info "GRPC_PYTHON_CFLAGS=${GRPC_PYTHON_CFLAGS}"
    log_info "GRPC_PYTHON_LDFLAGS=${GRPC_PYTHON_LDFLAGS}"

    log_info "Installing remaining build dependencies from requirements.txt"
    python -m pip install -r requirements.txt

    # For versions < v1.62.3, use Cython 0.29.37
    pkg_ver="${PACKAGE_VERSION#v}"
    if [[ "$(printf "%s\n" "$pkg_ver" "1.62.3" | sort -V | head -n1)" == "$pkg_ver" ]]; then
        log_info "Version $PACKAGE_VERSION < v1.62.3, installing Cython==0.29.37"
        python -m pip install --force-reinstall Cython==0.29.37
    fi
}


# =============================================================================
# CALLBACK: post_build — copy wheel into the artifact directory
# =============================================================================
post_build() {
    log_info "Packaging grpcio wheel into artifact directory..."

    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir "grpcio" "${PACKAGE_VERSION}")"

    # Find the repaired wheel (written to OUTPUT_DIR by _process_and_package_wheels)
    local wheel_file
    wheel_file=$(ls "${OUTPUT_DIR:-/output}"/grpcio-*.whl 2>/dev/null | head -1)
    if [[ -z "${wheel_file}" ]]; then
        wheel_file=$(ls wheelhouse/grpcio-*.whl 2>/dev/null | head -1)
    fi
    if [[ -z "${wheel_file}" ]]; then
        wheel_file=$(ls dist/grpcio-*.whl 2>/dev/null | head -1)
    fi

    if [[ -n "${wheel_file}" ]]; then
        log_info "Copying grpcio wheel to artifact: ${ARTIFACT_DIR}/wheels/"
        mkdir -p "${ARTIFACT_DIR}/wheels"
        cp "${wheel_file}" "${ARTIFACT_DIR}/wheels/"
        log_info "grpcio artifact wheel saved: $(basename "${wheel_file}")"
    else
        log_warn "No grpcio wheel found to copy into artifact — skipping wheels/ dir"
    fi
}


# =============================================================================
# CALLBACK: custom_test_command — import smoke test for grpcio modules
# =============================================================================
custom_test_command() {
    log_info "Running import smoke test for grpcio modules"

    # Change to parent directory to avoid importing from source tree
    cd ..

    python -c "
import grpc
import grpc._cython
import grpc._cython._cygrpc
import grpc.beta
import grpc.framework
import grpc.framework.common
import grpc.framework.foundation
import grpc.framework.interfaces
import grpc.framework.interfaces.base
import grpc.framework.interfaces.face
print('All grpcio modules imported successfully')
"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

