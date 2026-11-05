#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : libgoogle-cloud-storage
# Version       : v3.6.0
# Source repo   : https://github.com/googleapis/google-cloud-cpp
# Tested on     : UBI:10.2
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivender Singh <shivender.singh2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=libgoogle-cloud-storage
SCRIPT_PACKAGE_VERSION="v3.6.0"
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL="https://github.com/googleapis/google-cloud-cpp"
PACKAGE_DIR="google-cloud-cpp"

BUILD_HOME=$(pwd)
WORKING_DIR=$(pwd)
SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')

# Detect CPU generation and set Power10 optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected - no arch-specific flags applied"
fi

# Install dependencies
yum install -y --allowerasing \
    wget \
    git \
    cmake \
    ninja-build \
    make \
    gcc \
    gcc-c++ \
    openssl \
    openssl-devel \
    libcurl \
    libcurl-devel \
    libxml2 \
    libxml2-devel \
    zlib \
    zlib-devel \
    pkg-config \
    perl-FindBin \
    perl-File-Compare \
    python3 \
    python3-pip \
    python3-devel \
    python3-setuptools \
    ca-certificates

# Ensure pip tools and patchelf are installed
python3 -m pip install --upgrade pip setuptools wheel build patchelf 2>/dev/null || true

# Validate compiler flag support and fallback if necessary
if [ -n "${CPU_FLAGS}" ] && ! echo | gcc ${CPU_FLAGS} -E - >/dev/null 2>&1; then
    CPU_FLAGS=""
fi

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS} -O3"
export CXXFLAGS="${CPU_FLAGS} -O3"

gcc --version
g++ --version
cmake --version
python3 --version

# --- Step 0: Install Abseil-cpp, c-ares, RE2, Protobuf, gRPC, nlohmann_json, OpenTelemetry, GoogleTest, and Google Benchmark ---
# Order of installation: 1) Wheel -> 2) Build Script -> 3) Source Build
mkdir -p /usr/local/include /usr/local/lib64 /usr/local/lib /usr/local/lib64/cmake /usr/local/lib/cmake

# Helper to ensure system CMAKE_ROOT is never corrupted by dependency scripts installing into /usr/local/share/cmake
fix_cmake_root() {
    if [ -d "/usr/local/share/cmake" ] && [ ! -d "/usr/local/share/cmake/Modules" ]; then
        mkdir -p /usr/local/lib64/cmake /usr/local/lib/cmake
        cp -rf /usr/local/share/cmake/* /usr/local/lib64/cmake/ 2>/dev/null || true
        cp -rf /usr/local/share/cmake/* /usr/local/lib/cmake/ 2>/dev/null || true
        rm -rf /usr/local/share/cmake
    fi

    if [ -z "${CMAKE_ROOT:-}" ] || [ ! -d "${CMAKE_ROOT}/Modules" ]; then
        local SYS_MODS
        SYS_MODS=$(find /usr/share/cmake* /usr/lib*/cmake* -type d -name "Modules" 2>/dev/null | head -1)
        if [ -n "${SYS_MODS}" ] && [ -d "${SYS_MODS}" ]; then
            export CMAKE_ROOT="$(dirname "${SYS_MODS}")"
        fi
    fi
}

fix_cmake_root

# Set global CMake policies and arguments for compatibility across toolsets
export CMAKE_POLICY_VERSION_MINIMUM=3.5
export CMAKE_POLICY_DEFAULT_CMP0000=NEW
export CMAKE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 ${CMAKE_ARGS:-}"

# 1. Setup persistent dynamic linker configuration
mkdir -p /etc/ld.so.conf.d
cat >/etc/ld.so.conf.d/local.conf <<EOF
/usr/local/lib
/usr/local/lib64
EOF
ldconfig

# Helper functions for safe wheel extraction and package detection
extract_wheel_artifacts() {
    local PKG_DIR="$1"
    [ -z "${PKG_DIR}" ] || [ ! -d "${PKG_DIR}" ] && return 0
    echo "Safely extracting artifacts from ${PKG_DIR} -> /usr/local"
    [ -d "${PKG_DIR}/include" ] && cp -rf "${PKG_DIR}/include/"* /usr/local/include/ 2>/dev/null || true
    [ -d "${PKG_DIR}/lib64" ]   && cp -rf "${PKG_DIR}/lib64/"* /usr/local/lib64/ 2>/dev/null || true
    [ -d "${PKG_DIR}/lib" ]     && cp -rf "${PKG_DIR}/lib/"* /usr/local/lib/ 2>/dev/null || true

    # Safely merge cmake configs into /usr/local/lib64/cmake and /usr/local/lib/cmake
    # NEVER create or touch /usr/local/share/cmake directly to avoid corrupting CMAKE_ROOT
    if [ -d "${PKG_DIR}/share/cmake" ]; then
        mkdir -p /usr/local/lib64/cmake /usr/local/lib/cmake
        cp -rf "${PKG_DIR}/share/cmake/"* /usr/local/lib64/cmake/ 2>/dev/null || true
        cp -rf "${PKG_DIR}/share/cmake/"* /usr/local/lib/cmake/ 2>/dev/null || true
    fi
    for d in "${PKG_DIR}/share/"*; do
        if [ -d "$d" ] && [ "$(basename "$d")" != "cmake" ]; then
            mkdir -p /usr/local/share
            cp -rf "$d" /usr/local/share/ 2>/dev/null || true
        fi
    done
}

find_pkg_dir() {
    python3 -c "
import importlib.util
for m in ['$1', '$2', '$3', '$4']:
    if not m: continue
    s = importlib.util.find_spec(m)
    if s and s.submodule_search_locations:
        print(s.submodule_search_locations[0])
        break
" 2>/dev/null || true
}

# 0.1 Abseil-cpp
ABSEIL_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 -name 'abseil_cpp*.whl' 2>/dev/null | head -1)
if [ -n "${ABSEIL_WHEEL}" ]; then
    echo "Using Abseil wheel: ${ABSEIL_WHEEL}"
    python3 -m pip install "${ABSEIL_WHEEL}"
fi

ABSL_PKG_DIR=$(find_pkg_dir "abseil_cpp" "absl")
if [ -n "${ABSL_PKG_DIR}" ] && [ -d "${ABSL_PKG_DIR}" ]; then
    extract_wheel_artifacts "${ABSL_PKG_DIR}"
elif [ ! -f "/usr/local/lib64/libabsl_base.so" ] && [ ! -f "/usr/local/lib/libabsl_base.a" ] && [ ! -f "/usr/local/lib64/cmake/absl/abslConfig.cmake" ]; then
    ABSL_SCRIPT=""
    if [ -f "${SCRIPT_PATH}/abseil-cpp_ubi_10.2.sh" ]; then
        ABSL_SCRIPT="${SCRIPT_PATH}/abseil-cpp_ubi_10.2.sh"
    elif [ -f "${WORKING_DIR}/a/abseil-cpp/abseil-cpp_ubi_10.2.sh" ]; then
        ABSL_SCRIPT="${WORKING_DIR}/a/abseil-cpp/abseil-cpp_ubi_10.2.sh"
    elif [ -f "${WORKING_DIR}/abseil-cpp_ubi_10.2.sh" ]; then
        ABSL_SCRIPT="${WORKING_DIR}/abseil-cpp_ubi_10.2.sh"
    else
        wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/abseil-cpp/abseil-cpp_ubi_10.2.sh -O "${WORKING_DIR}/abseil-cpp_ubi_10.2.sh" 2>/dev/null || true
        [ -f "${WORKING_DIR}/abseil-cpp_ubi_10.2.sh" ] && ABSL_SCRIPT="${WORKING_DIR}/abseil-cpp_ubi_10.2.sh"
    fi

    if [ -n "${ABSL_SCRIPT}" ] && [ -f "${ABSL_SCRIPT}" ] && CMAKE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 ${CMAKE_ARGS:-}" bash "${ABSL_SCRIPT}" 20240116.2; then
        echo "Successfully built Abseil-cpp via build script (${ABSL_SCRIPT})"
        cd "${WORKING_DIR}"
    else
        echo "Abseil build script not found/failed. Building from source..."
        ABSL_DIR="${WORKING_DIR}/abseil-cpp"
        if [ ! -d "${ABSL_DIR}" ]; then
            git clone https://github.com/abseil/abseil-cpp.git "${ABSL_DIR}"
        fi
        cd "${ABSL_DIR}"
        git checkout 20240116.2 2>/dev/null || git checkout 20240722.0 2>/dev/null || true
        mkdir -p build && cd build
        cmake \
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_STANDARD=17 \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DABSL_PROPAGATE_CXX_STD=ON \
            -DBUILD_TESTING=OFF \
            -DCMAKE_INSTALL_PREFIX=/usr/local \
            -GNinja \
            ..
        ninja -j"$(nproc)"
        ninja install
        cd "${WORKING_DIR}"
    fi
    fix_cmake_root
fi
fix_cmake_root

# 0.2 c-ares
CARES_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 \( -name 'c_ares*.whl' -o -name 'c-ares*.whl' \) 2>/dev/null | head -1)
if [ -n "${CARES_WHEEL}" ]; then
    echo "Using c-ares wheel: ${CARES_WHEEL}"
    python3 -m pip install "${CARES_WHEEL}"
fi

CARES_PKG_DIR=$(find_pkg_dir "c_ares" "cares")
if [ -n "${CARES_PKG_DIR}" ] && [ -d "${CARES_PKG_DIR}" ]; then
    extract_wheel_artifacts "${CARES_PKG_DIR}"
elif [ ! -f "/usr/local/lib64/libcares.so" ] && [ ! -f "/usr/local/lib/libcares.so" ] && [ ! -f "/usr/local/include/ares.h" ]; then
    CARES_SCRIPT=""
    if [ -f "${SCRIPT_PATH}/cares_ubi_10.2.sh" ]; then
        CARES_SCRIPT="${SCRIPT_PATH}/cares_ubi_10.2.sh"
    elif [ -f "${WORKING_DIR}/c/c-ares/cares_ubi_10.2.sh" ]; then
        CARES_SCRIPT="${WORKING_DIR}/c/c-ares/cares_ubi_10.2.sh"
    elif [ -f "${WORKING_DIR}/cares_ubi_10.2.sh" ]; then
        CARES_SCRIPT="${WORKING_DIR}/cares_ubi_10.2.sh"
    else
        wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/c/c-ares/cares_ubi_10.2.sh -O "${WORKING_DIR}/cares_ubi_10.2.sh" 2>/dev/null || true
        [ -f "${WORKING_DIR}/cares_ubi_10.2.sh" ] && CARES_SCRIPT="${WORKING_DIR}/cares_ubi_10.2.sh"
    fi

    if [ -n "${CARES_SCRIPT}" ] && [ -f "${CARES_SCRIPT}" ] && CMAKE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 ${CMAKE_ARGS:-}" bash "${CARES_SCRIPT}" cares-1_19_1; then
        echo "Successfully built c-ares via build script (${CARES_SCRIPT})"
        cd "${WORKING_DIR}"
    else
        echo "c-ares build script not found/failed. Building from source..."
        CARES_DIR="${WORKING_DIR}/c-ares"
        if [ ! -d "${CARES_DIR}" ]; then
            git clone https://github.com/c-ares/c-ares.git "${CARES_DIR}"
        fi
        cd "${CARES_DIR}"
        git checkout cares-1_19_1 2>/dev/null || git checkout v1.19.1 2>/dev/null || true
        mkdir -p build && cd build
        cmake \
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DCARES_STATIC=OFF \
            -DCARES_SHARED=ON \
            -DCMAKE_INSTALL_PREFIX=/usr/local \
            -GNinja \
            ..
        ninja -j"$(nproc)"
        ninja install
        cd "${WORKING_DIR}"
    fi
    fix_cmake_root
fi
fix_cmake_root

# 0.3 re2
RE2_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 -name 're2*.whl' 2>/dev/null | head -1)
if [ -n "${RE2_WHEEL}" ]; then
    echo "Using RE2 wheel: ${RE2_WHEEL}"
    python3 -m pip install "${RE2_WHEEL}"
fi

RE2_PKG_DIR=$(find_pkg_dir "re2")
if [ -n "${RE2_PKG_DIR}" ] && [ -d "${RE2_PKG_DIR}" ]; then
    extract_wheel_artifacts "${RE2_PKG_DIR}"
elif [ ! -f "/usr/local/lib64/libre2.so" ] && [ ! -f "/usr/local/lib/libre2.so" ] && [ ! -f "/usr/local/include/re2/re2.h" ]; then
    RE2_SCRIPT=""
    if [ -f "${SCRIPT_PATH}/re2_ubi_10.2.sh" ]; then
        RE2_SCRIPT="${SCRIPT_PATH}/re2_ubi_10.2.sh"
    elif [ -f "${WORKING_DIR}/r/re2/re2_ubi_10.2.sh" ]; then
        RE2_SCRIPT="${WORKING_DIR}/r/re2/re2_ubi_10.2.sh"
    elif [ -f "${WORKING_DIR}/re2_ubi_10.2.sh" ]; then
        RE2_SCRIPT="${WORKING_DIR}/re2_ubi_10.2.sh"
    else
        wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/r/re2/re2_ubi_10.2.sh -O "${WORKING_DIR}/re2_ubi_10.2.sh" 2>/dev/null || true
        [ -f "${WORKING_DIR}/re2_ubi_10.2.sh" ] && RE2_SCRIPT="${WORKING_DIR}/re2_ubi_10.2.sh"
    fi

    if [ -n "${RE2_SCRIPT}" ] && [ -f "${RE2_SCRIPT}" ] && CMAKE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 ${CMAKE_ARGS:-}" bash "${RE2_SCRIPT}" 2022-04-01; then
        echo "Successfully built RE2 via build script (${RE2_SCRIPT})"
        cd "${WORKING_DIR}"
    else
        echo "RE2 build script not found/failed. Building from source..."
        RE2_DIR="${WORKING_DIR}/re2"
        if [ ! -d "${RE2_DIR}" ]; then
            git clone https://github.com/google/re2.git "${RE2_DIR}"
        fi
        cd "${RE2_DIR}"
        git checkout 2022-04-01 2>/dev/null || true
        mkdir -p build && cd build
        cmake \
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_STANDARD=17 \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DBUILD_SHARED_LIBS=ON \
            -DRE2_BUILD_TESTING=OFF \
            -DCMAKE_INSTALL_PREFIX=/usr/local \
            -GNinja \
            ..
        ninja -j"$(nproc)"
        ninja install
        cd "${WORKING_DIR}"
    fi
    fix_cmake_root
fi
fix_cmake_root

# 0.4 libprotobuf
PROTOBUF_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 -name '*protobuf*.whl' 2>/dev/null | head -1)
if [ -n "${PROTOBUF_WHEEL}" ]; then
    echo "Using Protobuf wheel: ${PROTOBUF_WHEEL}"
    python3 -m pip install "${PROTOBUF_WHEEL}"
fi

PROTOBUF_PKG_DIR=$(find_pkg_dir "libprotobuf" "google.protobuf")
if [ -n "${PROTOBUF_PKG_DIR}" ] && [ -d "${PROTOBUF_PKG_DIR}" ]; then
    extract_wheel_artifacts "${PROTOBUF_PKG_DIR}"
elif [ ! -f "/usr/local/lib64/libprotobuf.so" ] && [ ! -f "/usr/local/lib/libprotobuf.so" ] && [ ! -f "/usr/local/include/google/protobuf/message.h" ]; then
    PROTOBUF_SCRIPT=""
    if [ -f "${SCRIPT_PATH}/libprotobuf_ubi_10.2_v33.6.sh" ]; then
        PROTOBUF_SCRIPT="${SCRIPT_PATH}/libprotobuf_ubi_10.2_v33.6.sh"
    elif [ -f "${WORKING_DIR}/l/libprotobuf/libprotobuf_ubi_10.2_v33.6.sh" ]; then
        PROTOBUF_SCRIPT="${WORKING_DIR}/l/libprotobuf/libprotobuf_ubi_10.2_v33.6.sh"
    elif [ -f "${WORKING_DIR}/libprotobuf_ubi_10.2_v33.6.sh" ]; then
        PROTOBUF_SCRIPT="${WORKING_DIR}/libprotobuf_ubi_10.2_v33.6.sh"
    else
        wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/l/libprotobuf/libprotobuf_ubi_10.2_v33.6.sh -O "${WORKING_DIR}/libprotobuf_ubi_10.2_v33.6.sh" 2>/dev/null || true
        [ -f "${WORKING_DIR}/libprotobuf_ubi_10.2_v33.6.sh" ] && PROTOBUF_SCRIPT="${WORKING_DIR}/libprotobuf_ubi_10.2_v33.6.sh"
    fi

    if [ -n "${PROTOBUF_SCRIPT}" ] && [ -f "${PROTOBUF_SCRIPT}" ] && CMAKE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 ${CMAKE_ARGS:-}" bash "${PROTOBUF_SCRIPT}" v28.0; then
        echo "Successfully built Protobuf via build script (${PROTOBUF_SCRIPT})"
        cd "${WORKING_DIR}"
    else
        echo "Protobuf build script not found/failed. Building from source..."
        PROTOBUF_DIR="${WORKING_DIR}/protobuf"
        if [ ! -d "${PROTOBUF_DIR}" ]; then
            git clone https://github.com/protocolbuffers/protobuf.git "${PROTOBUF_DIR}"
        fi
        cd "${PROTOBUF_DIR}"
        git checkout v28.0 2>/dev/null || git checkout v28.3 2>/dev/null || git checkout v33.6 2>/dev/null || true
        git submodule update --init --recursive 2>/dev/null || true
        mkdir -p build && cd build
        cmake \
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_STANDARD=17 \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -Dprotobuf_BUILD_TESTS=OFF \
            -Dprotobuf_ABSL_PROVIDER=package \
            -DCMAKE_PREFIX_PATH=/usr/local \
            -DCMAKE_INSTALL_PREFIX=/usr/local \
            -GNinja \
            ..
        ninja -j"$(nproc)"
        ninja install
        cd "${WORKING_DIR}"
    fi
    fix_cmake_root
fi
fix_cmake_root

# 0.5 grpc_cpp
GRPC_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 -name 'grpc_cpp*.whl' 2>/dev/null | head -1)
if [ -n "${GRPC_WHEEL}" ]; then
    echo "Using gRPC wheel: ${GRPC_WHEEL}"
    python3 -m pip install "${GRPC_WHEEL}"
fi

GRPC_PKG_DIR=$(find_pkg_dir "grpc_cpp" "grpccpp" "grpc")
if [ -n "${GRPC_PKG_DIR}" ] && [ -d "${GRPC_PKG_DIR}" ]; then
    extract_wheel_artifacts "${GRPC_PKG_DIR}"
elif [ ! -f "/usr/local/lib64/libgrpc++.so" ] && [ ! -f "/usr/local/lib/libgrpc++.so" ] && [ ! -f "/usr/local/include/grpcpp/grpcpp.h" ]; then
    GRPC_SCRIPT=""
    if [ -f "${SCRIPT_PATH}/grpc_cpp_ubi_10.2.sh" ]; then
        GRPC_SCRIPT="${SCRIPT_PATH}/grpc_cpp_ubi_10.2.sh"
    elif [ -f "${WORKING_DIR}/g/grpc-cpp/grpc_cpp_ubi_10.2.sh" ]; then
        GRPC_SCRIPT="${WORKING_DIR}/g/grpc-cpp/grpc_cpp_ubi_10.2.sh"
    elif [ -f "${WORKING_DIR}/grpc_cpp_ubi_10.2.sh" ]; then
        GRPC_SCRIPT="${WORKING_DIR}/grpc_cpp_ubi_10.2.sh"
    else
        wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/g/grpc-cpp/grpc_cpp_ubi_10.2.sh -O "${WORKING_DIR}/grpc_cpp_ubi_10.2.sh" 2>/dev/null || true
        [ -f "${WORKING_DIR}/grpc_cpp_ubi_10.2.sh" ] && GRPC_SCRIPT="${WORKING_DIR}/grpc_cpp_ubi_10.2.sh"
    fi

    if [ -n "${GRPC_SCRIPT}" ] && [ -f "${GRPC_SCRIPT}" ] && CMAKE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 ${CMAKE_ARGS:-}" bash "${GRPC_SCRIPT}" 1.80.0; then
        echo "Successfully built gRPC via build script (${GRPC_SCRIPT})"
        cd "${WORKING_DIR}"
    else
        echo "gRPC build script not found/failed. Building from source..."
        GRPC_DIR="${WORKING_DIR}/grpc"
        if [ ! -d "${GRPC_DIR}" ]; then
            git clone --recurse-submodules https://github.com/grpc/grpc.git "${GRPC_DIR}"
        fi
        cd "${GRPC_DIR}"
        git checkout v1.68.0 2>/dev/null || git checkout 1.80.0 2>/dev/null || true
        git submodule update --init --recursive 2>/dev/null || true
        mkdir -p build && cd build
        cmake \
            -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_STANDARD=17 \
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
            -DgRPC_INSTALL=ON \
            -DgRPC_BUILD_TESTS=OFF \
            -DgRPC_ABSL_PROVIDER=package \
            -DgRPC_PROTOBUF_PROVIDER=package \
            -DgRPC_RE2_PROVIDER=package \
            -DgRPC_CARES_PROVIDER=package \
            -DgRPC_SSL_PROVIDER=package \
            -DgRPC_ZLIB_PROVIDER=package \
            -DCMAKE_PREFIX_PATH=/usr/local \
            -DCMAKE_INSTALL_PREFIX=/usr/local \
            -GNinja \
            ..
        ninja -j"$(nproc)"
        ninja install
        cd "${WORKING_DIR}"
    fi
    fix_cmake_root
fi
fix_cmake_root

ldconfig

JSON_DIR="${WORKING_DIR}/json"
if [ ! -d "${JSON_DIR}" ]; then
    git clone https://github.com/nlohmann/json.git "${JSON_DIR}"
fi

if [ ! -f "/usr/local/share/cmake/nlohmann_json/nlohmann_jsonConfig.cmake" ] && \
   [ ! -f "/usr/local/lib64/cmake/nlohmann_json/nlohmann_jsonConfig.cmake" ] && \
   [ ! -f "/usr/local/lib/cmake/nlohmann_json/nlohmann_jsonConfig.cmake" ] && \
   [ ! -f "/usr/local/include/nlohmann/json.hpp" ]; then
    cd "${JSON_DIR}"
    git checkout v3.11.3 2>/dev/null || true
    mkdir -p build && cd build
    fix_cmake_root
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DJSON_BuildTests=OFF \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -GNinja \
        ..
    ninja install
    cd "${WORKING_DIR}"
    fix_cmake_root
fi

OTEL_DIR="${WORKING_DIR}/opentelemetry-cpp"
if [ ! -d "${OTEL_DIR}" ]; then
    git clone --depth=1 --branch v1.18.0 https://github.com/open-telemetry/opentelemetry-cpp.git "${OTEL_DIR}"
fi

if [ ! -f "${OTEL_DIR}/build/.stl_built" ]; then
    cd "${OTEL_DIR}"
    # Ensure <cstdint> is included for GCC 14/15 compatibility
    if [ -f "api/include/opentelemetry/logs/severity.h" ]; then
        grep -q "<cstdint>" api/include/opentelemetry/logs/severity.h || sed -i '1i #include <cstdint>' api/include/opentelemetry/logs/severity.h
    fi
    find api/include/ -type f -name "*.h" -exec sed -i '1{/^#include <cstdint>/!s/^/#include <cstdint>\n/}' {} + 2>/dev/null || true
    rm -rf build
    mkdir -p build && cd build
    fix_cmake_root
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_TESTING=OFF \
        -DWITH_EXAMPLES=OFF \
        -DWITH_IN_MEMORY=ON \
        -DWITH_STL=ON \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -GNinja \
        ..
    ninja -j"$(nproc)"
    ninja install
    touch "${OTEL_DIR}/build/.stl_built"
    cd "${WORKING_DIR}"
    fix_cmake_root
fi

GTEST_DIR="${WORKING_DIR}/googletest"
if [ ! -d "${GTEST_DIR}" ]; then
    git clone https://github.com/google/googletest.git "${GTEST_DIR}"
fi

if [ ! -f "/usr/local/lib64/cmake/GTest/GTestConfig.cmake" ] && [ ! -f "/usr/local/lib/cmake/GTest/GTestConfig.cmake" ] && [ ! -f "/usr/local/include/gtest/gtest.h" ]; then
    cd "${GTEST_DIR}"
    git checkout v1.15.2 2>/dev/null || true
    mkdir -p build && cd build
    fix_cmake_root
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -GNinja \
        ..
    ninja -j"$(nproc)"
    ninja install
    cd "${WORKING_DIR}"
    fix_cmake_root
fi

BENCH_DIR="${WORKING_DIR}/benchmark"
if [ ! -d "${BENCH_DIR}" ]; then
    git clone https://github.com/google/benchmark.git "${BENCH_DIR}"
fi

if [ ! -f "/usr/local/lib64/cmake/benchmark/benchmarkConfig.cmake" ] && [ ! -f "/usr/local/lib/cmake/benchmark/benchmarkConfig.cmake" ] && [ ! -f "/usr/local/include/benchmark/benchmark.h" ]; then
    cd "${BENCH_DIR}"
    git checkout v1.9.0 2>/dev/null || true
    mkdir -p build && cd build
    fix_cmake_root
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBENCHMARK_ENABLE_TESTING=OFF \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -GNinja \
        ..
    ninja -j"$(nproc)"
    ninja install
    cd "${WORKING_DIR}"
    fix_cmake_root
fi

# Clone source only if not already present
if [ ! -d "$PACKAGE_DIR/.git" ]; then
    if ! git clone --recurse-submodules "$PACKAGE_URL" "$PACKAGE_DIR"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
        exit 1
    fi
fi

cd "$PACKAGE_DIR"

# Update existing repo
git fetch --all --tags

git checkout "$PACKAGE_VERSION" || git checkout "v${PACKAGE_VERSION#v}" || true

git submodule update --init --recursive

SOURCE_DIR=$(pwd)

# Ensure working directory is SOURCE_DIR and clean existing build directory
cd "$SOURCE_DIR"
rm -rf build
mkdir -p build && cd build
fix_cmake_root

# Build google-cloud-cpp with Storage component enabled
if ! cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_PREFIX_PATH=/usr/local \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib" \
    -DBUILD_TESTING=ON \
    -DGOOGLE_CLOUD_CPP_ENABLE_EXAMPLES=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DGOOGLE_CLOUD_CPP_ENABLE_WERROR=OFF \
    -DGOOGLE_CLOUD_CPP_ENABLE_GRPC=OFF \
    -DGOOGLE_CLOUD_CPP_STORAGE_ENABLE_GRPC=OFF \
    -DGOOGLE_CLOUD_CPP_ENABLE="storage,-universe_domain" \
    -GNinja \
    ..; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! ninja -j"$(nproc)"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Install to system prefix (/usr/local) for ctest and system usage
if ! DESTDIR="" ninja install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

cd "$SOURCE_DIR"

# Define local prefix for wheel packaging
mkdir -p local/libgoogle_cloud_storage
PREFIX="${SOURCE_DIR}/local/libgoogle_cloud_storage"
mkdir -p "${PREFIX}/include" "${PREFIX}/lib" "${PREFIX}/lib64" "${PREFIX}/share"

# Copy all Google Cloud C++ headers and libraries from /usr/local into PREFIX
if [ -d "/usr/local/include/google" ]; then
    cp -rf /usr/local/include/google "${PREFIX}/include/" 2>/dev/null || true
fi
cp -d /usr/local/lib64/libgoogle_cloud_cpp*.so* "${PREFIX}/lib64/" 2>/dev/null || true
cp -d /usr/local/lib/libgoogle_cloud_cpp*.so* "${PREFIX}/lib/" 2>/dev/null || true

# Copy all dependency headers and libraries (Abseil, JSON, OpenTelemetry, Protobuf, gRPC, RE2, c-ares, etc.) into PREFIX
for dep in absl nlohmann opentelemetry grpc grpcpp re2 google; do
    if [ -d "/usr/local/include/${dep}" ]; then
        cp -rf "/usr/local/include/${dep}" "${PREFIX}/include/" 2>/dev/null || true
    fi
done
[ -f "/usr/local/include/ares.h" ] && cp -f /usr/local/include/ares*.h "${PREFIX}/include/" 2>/dev/null || true

cp -d /usr/local/lib64/libabsl*.so* "${PREFIX}/lib64/" 2>/dev/null || true
cp -d /usr/local/lib/libabsl*.so* "${PREFIX}/lib/" 2>/dev/null || true
cp -d /usr/local/lib64/libopentelemetry*.so* "${PREFIX}/lib64/" 2>/dev/null || true
cp -d /usr/local/lib/libopentelemetry*.so* "${PREFIX}/lib/" 2>/dev/null || true
cp -d /usr/local/lib64/libprotobuf*.so* "${PREFIX}/lib64/" 2>/dev/null || true
cp -d /usr/local/lib/libprotobuf*.so* "${PREFIX}/lib/" 2>/dev/null || true
cp -d /usr/local/lib64/libgrpc*.so* "${PREFIX}/lib64/" 2>/dev/null || true
cp -d /usr/local/lib/libgrpc*.so* "${PREFIX}/lib/" 2>/dev/null || true
cp -d /usr/local/lib64/libre2*.so* "${PREFIX}/lib64/" 2>/dev/null || true
cp -d /usr/local/lib/libre2*.so* "${PREFIX}/lib/" 2>/dev/null || true
cp -d /usr/local/lib64/libcares*.so* "${PREFIX}/lib64/" 2>/dev/null || true
cp -d /usr/local/lib/libcares*.so* "${PREFIX}/lib/" 2>/dev/null || true

# Patch RPATH/RUNPATH on all shared libraries inside wheel prefix so dependencies resolve via $ORIGIN
if ! command -v patchelf >/dev/null 2>&1; then
    python3 -m pip install patchelf 2>/dev/null || true
fi
find "${PREFIX}" -type f -name "*.so*" | while read -r so_file; do
    patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib64:$ORIGIN/../lib' "$so_file" 2>/dev/null || true
done

# Create Python package init file
touch "${PREFIX}/__init__.py"

# Verify content of packaging directory before wheel creation
echo "=== CONTENT OF PACKAGE DIRECTORY (${PREFIX}) ==="
find "${PREFIX}" -type f | sort

# Smoke-test: verify shared libraries and headers for libgoogle-cloud-storage
ldconfig /usr/local/lib64 /usr/local/lib 2>/dev/null || true
if ! ls /usr/local/include/google/cloud/storage/client.h > /dev/null 2>&1 || \
   ! ls /usr/local/lib*/libgoogle_cloud_cpp_storage.so* > /dev/null 2>&1; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run C++ unit tests, signed URL conformance, and benchmark/inclusion tests
cd "$SOURCE_DIR/build"
export LD_LIBRARY_PATH="/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH:-}"
if ! ctest --output-on-failure -j"$(nproc)" \
    -LE "integration-test|integration-test-emulator|integration-test-gha|quickstart"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# --- 3. Build Python Wheel via Python Binding / Setuptools ---
cd "$SOURCE_DIR"
python3 -m pip install --upgrade pip setuptools wheel build

# Locate pyproject.toml
if [ -f "${SCRIPT_PATH}/pyproject.toml" ]; then
    cp "${SCRIPT_PATH}/pyproject.toml" pyproject.toml
elif [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    cp "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" pyproject.toml
elif [ -f "${WORKING_DIR}/l/libgoogle-cloud-storage/pyproject.toml" ]; then
    cp "${WORKING_DIR}/l/libgoogle-cloud-storage/pyproject.toml" pyproject.toml
elif [ -f "${WORKING_DIR}/libgoogle-cloud-storage/pyproject.toml" ]; then
    cp "${WORKING_DIR}/libgoogle-cloud-storage/pyproject.toml" pyproject.toml
elif [ -f "${WORKING_DIR}/pyproject.toml" ]; then
    cp "${WORKING_DIR}/pyproject.toml" pyproject.toml
else
    wget https://raw.githubusercontent.com/shivender-singh/build-scripts/libgoogle-cloud-storage/l/libgoogle-cloud-storage/pyproject.toml 2>/dev/null || \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/l/libgoogle-cloud-storage/pyproject.toml 2>/dev/null || true
fi

# Sanitize version string (e.g. v3.6.0 -> 3.6.0)
CLEAN_VERSION="${PACKAGE_VERSION#v}"
sed -i "s/{PACKAGE_VERSION}/${CLEAN_VERSION}/g" pyproject.toml

if ! python3 -m pip install . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Produce libgoogle-cloud-storage wheel artifact
python3 -m build --wheel --no-isolation

cd "$WORKING_DIR"

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
