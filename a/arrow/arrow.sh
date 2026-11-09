#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : arrow
# Version       : apache-arrow-19.0.1
# Source repo   : https://github.com/apache/arrow
# Tested on     : UBI:9.6
# Language      : C++
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# IMPORTANT: Use exact GitHub tag format (apache-arrow-X.Y.Z)
# =============================================================================
PACKAGE_NAME="arrow"
PACKAGE_VERSION="${1:-apache-arrow-19.0.1}"
# Accept a bare version (21.0.0) as well as the git tag (apache-arrow-21.0.0)
[[ "${PACKAGE_VERSION}" == apache-arrow-* ]] || PACKAGE_VERSION="apache-arrow-${PACKAGE_VERSION#v}"
PACKAGE_URL="https://github.com/apache/arrow"

# =============================================================================
# Artifact Declaration (Tier 3 - many dependencies)
# These dependencies must be built first in order
# =============================================================================
PROVIDES_ARTIFACT="arrow"
# Versions come from build_info.json (per apache-arrow-X.Y.Z block) via the
# BUILD_DEPS env var; the value below is the fallback for local runs.
# build_info.json lists the thrift package as "thrift-cpp" but it provides the
# artifact "thrift", so normalise the name.
BUILD_DEPS="${BUILD_DEPS:-grpc_cpp:v1.68.0 boost thrift utf8proc snappy zstd re2:2024-07-02 xsimd rapidjson gflags c-ares:v1.33.1 libprotobuf:v28.2 abseil-cpp:20240722.0}"
BUILD_DEPS="${BUILD_DEPS//thrift-cpp/thrift}"

# =============================================================================
# REQUIRED: Dependencies
# Note: Many dependencies come from artifacts, not system packages
# =============================================================================
RH_DEP_PKGS="git cmake make ninja-build bzip2-devel lz4-devel zlib-devel brotli-devel openssl-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_install
# Build Apache Arrow C++ library and install to artifact directory
#
# This is a complex build with the following steps:
# 1. Source all dependency artifacts
# 2. Build CMAKE_PREFIX_PATH from all dependencies
# 3. Apply architecture-specific configurations
# 4. Apply jemalloc page size patch for ppc64le
# 5. Configure with many Arrow-specific CMake options
# 6. Build and install with Ninja
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir arrow "${ARTIFACT_VERSION}")"

    # Check if already built (idempotency)
    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Arrow artifact already exists at ${ARTIFACT_DIR}"
        return
    fi

    # -------------------------------------------------------------------------
    # Source all required dependency artifacts
    # Order matters for CMAKE_PREFIX_PATH construction
    # -------------------------------------------------------------------------
    log_info "Sourcing dependency artifacts..."

    local dep
    for dep in ${BUILD_DEPS}; do
        local dep_name="${dep%%:*}"
        local dep_version=""
        if [[ "${dep}" == *":"* ]]; then
            dep_version="${dep#*:}"
        fi
        if ! source_artifact "${dep_name}" "${dep_version}"; then
            log_error "${dep} artifact not found!"
            log_error "Build ${dep} first before building arrow"
            false
        fi
    done

    # -------------------------------------------------------------------------
    # Build CMAKE_PREFIX_PATH from all dependency prefixes
    # Each artifact's env.sh should set *_PREFIX variables
    # -------------------------------------------------------------------------
    log_info "Building CMAKE_PREFIX_PATH from dependencies..."

    # Construct prefix path - order matters for CMake find_package.
    # IMPORTANT: cmake -DCMAKE_PREFIX_PATH requires SEMICOLONS as list separators.
    # Variable names are derived from artifact names by _generate_env_sh:
    #   tr '[:lower:]-' '[:upper:]_' then append _PREFIX
    # e.g. libprotobuf -> LIBPROTOBUF_PREFIX, abseil-cpp -> ABSEIL_CPP_PREFIX
    local CMAKE_PREFIX_PARTS=""
    CMAKE_PREFIX_PARTS="${C_ARES_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${LIBPROTOBUF_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${RE2_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${ABSEIL_CPP_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${GRPC_CPP_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${BOOST_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${UTF8PROC_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${THRIFT_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${SNAPPY_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${ZSTD_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${XSIMD_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${RAPIDJSON_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};${GFLAGS_PREFIX:-}"
    CMAKE_PREFIX_PARTS="${CMAKE_PREFIX_PARTS};/usr"

    # Clean up empty entries (remove leading/trailing/doubled semicolons)
    CMAKE_PREFIX_PARTS=$(echo "${CMAKE_PREFIX_PARTS}" | sed 's/^;//;s/;;*/;/g;s/;$//')

    export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PARTS}"
    log_info "CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"

    # -------------------------------------------------------------------------
    # Belt-and-suspenders: patch ThriftConfig.cmake if it still has hardcoded
    # build-time absolute paths from a stale artifact. The set_and_check() macro
    # issues a FATAL_ERROR when those paths don't exist, causing FindThriftAlt
    # to fail even though thrift.so is present and CMAKE_PREFIX_PATH is correct.
    # -------------------------------------------------------------------------
    if [[ -n "${THRIFT_PREFIX:-}" ]]; then
        local _thrift_cmake="${THRIFT_PREFIX}/lib/cmake/thrift/ThriftConfig.cmake"
        if [[ -f "${_thrift_cmake}" ]]; then
            if grep -q 'set_and_check(THRIFT_INCLUDE_DIR "/' "${_thrift_cmake}" && \
               ! grep -q 'PACKAGE_PREFIX_DIR' "${_thrift_cmake}"; then
                log_warn "Patching stale ThriftConfig.cmake at ${_thrift_cmake}..."
                sed -i \
                    -e 's|set_and_check(THRIFT_INCLUDE_DIR "[^"]*")|set_and_check(THRIFT_INCLUDE_DIR "${PACKAGE_PREFIX_DIR}/include/thrift")|g' \
                    -e 's|set_and_check(THRIFT_CMAKE_DIR "[^"]*")|set_and_check(THRIFT_CMAKE_DIR "${PACKAGE_PREFIX_DIR}/lib/cmake/thrift")|g' \
                    -e 's|set_and_check(THRIFT_BIN_DIR "[^"]*")|set_and_check(THRIFT_BIN_DIR "${PACKAGE_PREFIX_DIR}/bin")|g' \
                    -e 's|find_dependency(Libevent)|find_package(Libevent QUIET)|g' \
                    "${_thrift_cmake}"
                log_info "ThriftConfig.cmake patched successfully"
            fi
        fi
    fi

    # -------------------------------------------------------------------------
    # Set up build environment
    # -------------------------------------------------------------------------
    log_info "Building Arrow ${PACKAGE_VERSION} to ${ARTIFACT_DIR}"
    mkdir -p "${ARTIFACT_DIR}"

    local target_platform
    target_platform="$(uname)-$(uname -m)"
    log_info "Target platform: ${target_platform}"

    export CXX=$(which g++)
    export AR=$(which ar)
    export RANLIB=$(which ranlib)

    # Set Boost environment variables for cmake FindBoost module.
    # CMake 3.27+ (CMP0144) only honours mixed-case <PackageName>_ROOT in
    # find_package, so set both Boost_ROOT (respected) and BOOST_ROOT (legacy).
    export BOOST_ROOT="${BOOST_PREFIX:-}"
    export Boost_ROOT="${BOOST_PREFIX:-}"
    export BOOST_INCLUDEDIR="${BOOST_PREFIX:-}/include"
    export BOOST_LIBRARYDIR="${BOOST_PREFIX:-}/lib"

    # Include paths for headers
    export CXXFLAGS="-I${BOOST_PREFIX:-}/include -I${THRIFT_PREFIX:-}/include"

    # -------------------------------------------------------------------------
    # Build extra CMake arguments based on architecture
    # -------------------------------------------------------------------------
    local EXTRA_CMAKE_ARGS=""

    # Include g++'s system headers for Gandiva (if enabled)
    if [[ "$(uname)" == "Linux" ]]; then
        local SYSTEM_INCLUDES
        SYSTEM_INCLUDES=$(echo | ${CXX} -E -Wp,-v -xc++ - 2>&1 | grep '^ ' | awk '{print "-isystem;" substr($1, 1)}' | tr '\n' ';')
        EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DARROW_GANDIVA_PC_CXX_FLAGS=${SYSTEM_INCLUDES}"
    fi

    # SIMD settings per architecture
    if [[ "${target_platform}" == "Linux-x86_64" ]]; then
        EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DARROW_SIMD_LEVEL=SSE4_2"
    fi
    if [[ "${target_platform}" == "Linux-ppc64le" ]]; then
        EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DARROW_ALTIVEC=ON"
    fi

    # Use gold linker on non-s390x Linux
    if [[ "${target_platform}" != "Linux-s390x" ]]; then
        EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DARROW_USE_LD_GOLD=ON"
    fi

    # Disable CUDA support (can be enabled via build_type=cuda)
    EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DARROW_CUDA=OFF"

    # Disable Gandiva (LLVM dependency, complex to build)
    EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS} -DARROW_GANDIVA=OFF"

    # -------------------------------------------------------------------------
    # Apply jemalloc page size patch for ppc64le (16KB pages)
    # -------------------------------------------------------------------------
    if [[ "${target_platform}" == "Linux-ppc64le" ]]; then
        log_info "Applying jemalloc page size patch for ppc64le..."
        sed -i 's;"--with-jemalloc-prefix\=je_arrow_";"--with-jemalloc-prefix\=je_arrow_" "--with-lg-page\=16";g' \
            cpp/cmake_modules/ThirdpartyToolchain.cmake || {
            log_warn "Failed to apply jemalloc patch (may not be needed for this version)"
        }
    fi

    # -------------------------------------------------------------------------
    # Create build directory and run CMake
    # Arrow build is in the cpp/ subdirectory
    # -------------------------------------------------------------------------
    mkdir -p cpp/build
    cd cpp/build

    # ORC is built from Arrow's bundled source (-Dorc_SOURCE=BUNDLED below), and
    # the orc artifact is deliberately NOT a dependency of this build:
    #  1. The artifact's liborc.a is compiled against ORC's vendored protobuf 3.5.1
    #     headers, so it references MessageLite::ParseFromString(const std::string&),
    #     which the libprotobuf artifact (25.x/27.x/28.x) does not export.  Importing
    #     pyarrow then fails with "undefined symbol: ..MessageLite15ParseFromString..".
    #  2. If the orc artifact is sourced, its include dir lands on CPATH.  CPATH is
    #     searched before the -isystem dirs CMake adds for the bundled ORC, so
    #     Arrow's ORC adapter is compiled against the artifact's ORC headers (2.0.3)
    #     while linking the bundled ORC library (2.2.x).  ORC 2.2.0 added virtual
    #     methods (Type::getCrs/getAlgorithm), shifting vtable slots, so
    #     orc::Type::createRowBatch jumps to a garbage address: the segfault in
    #     orc.write_table / test_orc_format.

    log_info "Running CMake to configure Arrow build..."
    cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
        \
        -DARROW_DEPENDENCY_SOURCE=SYSTEM \
        -DBUILD_SHARED_LIBS=ON \
        -DARROW_BUILD_STATIC=OFF \
        \
        -DARROW_BUILD_BENCHMARKS=OFF \
        -DARROW_BUILD_TESTS=OFF \
        -DARROW_BUILD_UTILITIES=OFF \
        \
        -DARROW_BOOST_USE_SHARED=ON \
        -DARROW_DATASET=ON \
        -DARROW_FLIGHT=ON \
        -DARROW_FLIGHT_SQL=ON \
        -DARROW_HDFS=ON \
        -DARROW_JEMALLOC=ON \
        -DARROW_MIMALLOC=ON \
        -DARROW_ORC=ON \
        -DARROW_PARQUET=ON \
        -DARROW_PYTHON=ON \
        -DARROW_S3=OFF \
        \
        -DARROW_WITH_BROTLI=ON \
        -DARROW_WITH_BZ2=ON \
        -DARROW_WITH_LZ4=ON \
        -DARROW_WITH_SNAPPY=ON \
        -DARROW_WITH_ZLIB=ON \
        -DARROW_WITH_ZSTD=ON \
        -DARROW_WITH_THRIFT=ON \
        \
        -DARROW_PACKAGE_PREFIX="${ARTIFACT_DIR}" \
        \
        -DPYTHON_EXECUTABLE=python3 \
        -DPython3_EXECUTABLE=python3 \
        \
        -DProtobuf_PROTOC_EXECUTABLE="${LIBPROTOBUF_PREFIX:-}/bin/protoc" \
        -Dprotobuf_ROOT="${LIBPROTOBUF_PREFIX:-}" \
        -DProtobuf_ROOT="${LIBPROTOBUF_PREFIX:-}" \
        -Dorc_SOURCE=BUNDLED \
        -DORC_SOURCE=BUNDLED \
        -DgRPC_DIR="${GRPC_CPP_PREFIX:-}" \
        -DBoost_ROOT="${BOOST_PREFIX:-}" \
        -DBOOST_ROOT="${BOOST_PREFIX:-}" \
        -DBoost_INCLUDE_DIR="${BOOST_PREFIX:-}/include" \
        -DBOOST_INCLUDEDIR="${BOOST_PREFIX:-}/include" \
        -DBOOST_LIBRARYDIR="${BOOST_PREFIX:-}/lib" \
        -DBoost_NO_SYSTEM_PATHS=ON \
        -Dutf8proc_LIB="${UTF8PROC_PREFIX:-}/lib/libutf8proc.so" \
        -Dutf8proc_INCLUDE_DIR="${UTF8PROC_PREFIX:-}/include" \
        \
        -DThrift_ROOT="${THRIFT_PREFIX:-}" \
        -DTHRIFT_ROOT="${THRIFT_PREFIX:-}" \
        -DThrift_DIR="${THRIFT_PREFIX:-}/lib/cmake/thrift" \
        -DARROW_THRIFT_USE_SHARED=ON \
        -DThrift_INCLUDE_DIR="${THRIFT_PREFIX:-}/include" \
        -DTHRIFT_COMPILER="${THRIFT_PREFIX:-}/bin/thrift" \
        \
        -DCMAKE_AR="${AR}" \
        -DCMAKE_RANLIB="${RANLIB}" \
        \
        ${EXTRA_CMAKE_ARGS} \
        .. || { log_error "Arrow CMake configure failed"; return 1; }

    # -------------------------------------------------------------------------
    # Build and install
    # -------------------------------------------------------------------------
    # custom_install runs under "if !", which disables errexit, so a failing
    # step must be propagated explicitly.  Otherwise a failed configure still
    # ends in a hollow artifact (env.sh only) reported as install_success.
    log_info "Building Arrow (this may take a while)..."
    ninja -j"$(nproc)" || { log_error "Arrow build failed"; return 1; }

    log_info "Installing Arrow..."
    ninja install || { log_error "Arrow install failed"; return 1; }

    cd ../..

    # -------------------------------------------------------------------------
    # Cleanup and finalization
    # -------------------------------------------------------------------------

    # Remove unnecessary files (man pages, docs)
    cleanup_artifact_dir "${ARTIFACT_DIR}" share

    # Copy license
    cp LICENSE.txt "${ARTIFACT_DIR}/LICENSE" || {
        # Some versions use different license file names
        cp LICENSE "${ARTIFACT_DIR}/" 2>/dev/null || true
    }

    # -------------------------------------------------------------------------
    # Generate env.sh for consumers (pyarrow)
    # -------------------------------------------------------------------------
    _generate_env_sh "${ARTIFACT_DIR}" "${PROVIDES_ARTIFACT}" "${ARTIFACT_VERSION}"

    # Add pyarrow-specific build variables not covered by _generate_env_sh
    cat >> "${ARTIFACT_DIR}/env.sh" << 'EOF'

# pyarrow build variables
export PARQUET_HOME="${ARROW_PREFIX}"
EOF

    # -------------------------------------------------------------------------
    # Generate manifest with all dependencies listed
    # -------------------------------------------------------------------------
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "arrow" "${ARTIFACT_VERSION}" \
        "${PACKAGE_URL}" "Apache-2.0" \
        "grpc_cpp" "boost" "thrift" "utf8proc" "snappy" "zstd" "re2" \
        "xsimd" "rapidjson" "gflags" "c-ares" "libprotobuf" "abseil-cpp"

    log_info "Arrow installed to ${ARTIFACT_DIR}"
}

# Tests require -DARROW_BUILD_TESTS=ON rebuild; skipped for artifact-provider builds
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
LICENSE_SPDX="Apache-2.0"
source "${SCRIPT_DIR}/../../v2-templates/base.sh"



