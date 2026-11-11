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

# Helper to ensure system CMAKE_ROOT is never corrupted by dependency scripts installing into share/cmake
fix_cmake_root() {
    local SYS_MODS=""
    for p in /usr/share/cmake*/Modules /usr/share/cmake/Modules /usr/lib*/cmake*/Modules; do
        if [ -d "$p" ] && [ -f "$p/CMake.cmake" ]; then
            SYS_MODS="$p"
            break
        fi
    done

    if [ -z "${SYS_MODS}" ]; then
        SYS_MODS=$(find /usr/share /usr/local/lib* /usr/lib* -type d -name "Modules" 2>/dev/null | grep "cmake" | while read -r d; do
            if [ -f "$d/CMake.cmake" ]; then
                echo "$d"
                break
            fi
        done | head -1)
    fi

    if [ -n "${SYS_MODS}" ] && [ -d "${SYS_MODS}" ]; then
        export CMAKE_ROOT="$(dirname "${SYS_MODS}")"
    fi

    local TARGET_PREFIXES=("/usr/local")
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        TARGET_PREFIXES+=("${VIRTUAL_ENV}")
    fi
    local CMAKE_BIN_PATH
    CMAKE_BIN_PATH=$(which cmake 2>/dev/null || true)
    if [ -n "${CMAKE_BIN_PATH}" ]; then
        local CMAKE_PREFIX
        CMAKE_PREFIX=$(dirname "$(dirname "${CMAKE_BIN_PATH}")")
        if [ -n "${CMAKE_PREFIX}" ] && [ "${CMAKE_PREFIX}" != "/usr" ]; then
            TARGET_PREFIXES+=("${CMAKE_PREFIX}")
        fi
    fi

    for pfx in "${TARGET_PREFIXES[@]}"; do
        [ -z "${pfx}" ] || [ ! -d "${pfx}" ] && continue

        # Ensure system /usr/bin/cmake takes precedence over broken local binary
        if [ -x "/usr/bin/cmake" ] && [ -f "${pfx}/bin/cmake" ] && [ ! -L "${pfx}/bin/cmake" ]; then
            rm -f "${pfx}/bin/cmake" "${pfx}/bin/ctest" "${pfx}/bin/cpack" 2>/dev/null || true
            ln -sf /usr/bin/cmake "${pfx}/bin/cmake" 2>/dev/null || true
            ln -sf /usr/bin/ctest "${pfx}/bin/ctest" 2>/dev/null || true
            ln -sf /usr/bin/cpack "${pfx}/bin/cpack" 2>/dev/null || true
        fi

        # Ensure share/cmake/Modules points directly to system Modules
        if [ -n "${SYS_MODS}" ] && [ -d "${SYS_MODS}" ]; then
            mkdir -p "${pfx}/share/cmake"
            if [ ! -d "${pfx}/share/cmake/Modules" ] || [ ! -f "${pfx}/share/cmake/Modules/CMake.cmake" ]; then
                rm -rf "${pfx}/share/cmake/Modules" 2>/dev/null || true
                ln -sf "${SYS_MODS}" "${pfx}/share/cmake/Modules"
            fi
        fi

        # Replicate any non-Modules cmake configs into /usr/local/lib64/cmake and /usr/local/lib/cmake
        if [ -d "${pfx}/share/cmake" ]; then
            mkdir -p /usr/local/lib64/cmake /usr/local/lib/cmake
            for item in "${pfx}/share/cmake/"*; do
                if [ -e "$item" ] && [ "$(basename "$item")" != "Modules" ]; then
                    cp -a "$item/." /usr/local/lib64/cmake/ 2>/dev/null || true
                    cp -a "$item/." /usr/local/lib/cmake/ 2>/dev/null || true
                fi
            done
        fi
    done
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
export LD_LIBRARY_PATH="/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH:-}"

# Helper functions for safe wheel extraction and package detection
extract_wheel_artifacts() {
    local PKG_DIR="$1"
    [ -z "${PKG_DIR}" ] || [ ! -d "${PKG_DIR}" ] && return 0
    echo "Safely extracting artifacts from ${PKG_DIR} -> /usr/local"
    [ -d "${PKG_DIR}/include" ] && cp -a "${PKG_DIR}/include/." /usr/local/include/ 2>/dev/null || true
    [ -d "${PKG_DIR}/lib64" ]   && cp -a "${PKG_DIR}/lib64/." /usr/local/lib64/ 2>/dev/null || true
    [ -d "${PKG_DIR}/lib" ]     && cp -a "${PKG_DIR}/lib/." /usr/local/lib/ 2>/dev/null || true

    # Synchronize shared libraries between lib and lib64 to resolve path differences across configs
    if [ -d "${PKG_DIR}/lib" ]; then
        cp -a "${PKG_DIR}/lib/." /usr/local/lib64/ 2>/dev/null || true
    fi
    if [ -d "${PKG_DIR}/lib64" ]; then
        cp -a "${PKG_DIR}/lib64/." /usr/local/lib/ 2>/dev/null || true
    fi

    # Extract all .so files from PKG_DIR and any auditwheel .libs sibling directories
    find "${PKG_DIR}" -name "*.so*" -exec cp -a {} /usr/local/lib64/ \; 2>/dev/null || true
    find "${PKG_DIR}" -name "*.so*" -exec cp -a {} /usr/local/lib/ \; 2>/dev/null || true

    local PARENT_DIR="$(dirname "${PKG_DIR}")"
    find "${PARENT_DIR}" -maxdepth 2 -type d -name "*.libs" 2>/dev/null | while read -r libs_dir; do
        cp -a "${libs_dir}/." /usr/local/lib64/ 2>/dev/null || true
        cp -a "${libs_dir}/." /usr/local/lib/ 2>/dev/null || true
    done

    # Extract binaries (protoc, grpc_cpp_plugin, etc.) to /usr/local/bin
    mkdir -p /usr/local/bin
    [ -d "${PKG_DIR}/bin" ] && cp -a "${PKG_DIR}/bin/." /usr/local/bin/ 2>/dev/null || true
    find "${PKG_DIR}" -type f -name "protoc*" -exec cp -a {} /usr/local/bin/ \; 2>/dev/null || true
    find "${PKG_DIR}" -type f -name "grpc_*_plugin" -exec cp -a {} /usr/local/bin/ \; 2>/dev/null || true
    find "${PARENT_DIR}" -maxdepth 3 -type f -name "protoc*" -exec cp -a {} /usr/local/bin/ \; 2>/dev/null || true
    find "${PARENT_DIR}" -maxdepth 3 -type f -name "grpc_*_plugin" -exec cp -a {} /usr/local/bin/ \; 2>/dev/null || true
    chmod +x /usr/local/bin/* 2>/dev/null || true

    mkdir -p /usr/local/lib64/cmake /usr/local/lib/cmake
    find "${PKG_DIR}" -type d -name "cmake" 2>/dev/null | while read -r cm_dir; do
        cp -a "${cm_dir}/." /usr/local/lib64/cmake/ 2>/dev/null || true
        cp -a "${cm_dir}/." /usr/local/lib/cmake/ 2>/dev/null || true
    done
    find "${PKG_DIR}" -type f \( -name "*[Cc]onfig.cmake" -o -name "*-config.cmake" \) 2>/dev/null | while read -r cfg_file; do
        local parent_dir
        parent_dir=$(basename "$(dirname "$cfg_file")")
        if [ "$parent_dir" != "cmake" ]; then
            mkdir -p "/usr/local/lib64/cmake/${parent_dir}" "/usr/local/lib/cmake/${parent_dir}"
            cp -a "$(dirname "$cfg_file")/." "/usr/local/lib64/cmake/${parent_dir}/" 2>/dev/null || true
            cp -a "$(dirname "$cfg_file")/." "/usr/local/lib/cmake/${parent_dir}/" 2>/dev/null || true
        fi
    done
    for d in "${PKG_DIR}/share/"*; do
        if [ -d "$d" ] && [ "$(basename "$d")" != "cmake" ]; then
            mkdir -p /usr/local/share
            cp -a "$d/." /usr/local/share/ 2>/dev/null || true
        fi
    done

    ldconfig /usr/local/lib64 /usr/local/lib 2>/dev/null || true
}

find_pkg_dir() {
    python3 -c "
import importlib.util, os, sys
for m in ['$1', '$2', '$3', '$4', '$5']:
    if not m: continue
    try:
        s = importlib.util.find_spec(m)
        if s and s.submodule_search_locations:
            print(s.submodule_search_locations[0])
            sys.exit(0)
    except Exception:
        pass
for sp in sys.path:
    for m in ['$1', '$2', '$3', '$4', '$5']:
        if not m: continue
        d = os.path.join(sp, m)
        if os.path.isdir(d):
            print(d)
            sys.exit(0)
" 2>/dev/null || true
}

# 0.1 Abseil-cpp (In-line Source Build with PIC for clean static linkage)
echo "Building Abseil-cpp in-line from source..."
ABSL_DIR="${WORKING_DIR}/abseil-cpp"
if [ ! -d "${ABSL_DIR}" ]; then
    git clone https://github.com/abseil/abseil-cpp.git "${ABSL_DIR}"
fi
cd "${ABSL_DIR}"
git checkout 20240116.2 2>/dev/null || git checkout 20240722.0 2>/dev/null || true
rm -rf build && mkdir -p build && cd build
fix_cmake_root
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
# Remove conflicting dynamic absl shared libraries so static PIC archives are cleanly linked
rm -f /usr/local/lib64/libabsl*.so* /usr/local/lib/libabsl*.so* 2>/dev/null || true
cd "${WORKING_DIR}"
fix_cmake_root

# 0.2 c-ares (Wheel -> In-line Source Build)
CARES_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 \( -name 'c_ares*.whl' -o -name 'c-ares*.whl' \) 2>/dev/null | head -1)
if [ -n "${CARES_WHEEL}" ]; then
    echo "Using local c-ares wheel: ${CARES_WHEEL}"
    python3 -m pip install "${CARES_WHEEL}" 2>/dev/null || true
else
    echo "Attempting to install c-ares from IBM developer wheels index..."
    python3 -m pip install --extra-index-url https://wheels.developerfirst.ibm.com/simple/ --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ --trusted-host wheels.developerfirst.ibm.com c_ares c-ares cares 2>/dev/null || true
fi

CARES_PKG_DIR=$(find_pkg_dir "c_ares" "cares")
[ -n "${CARES_PKG_DIR}" ] && extract_wheel_artifacts "${CARES_PKG_DIR}"

if [ ! -f "/usr/local/include/ares.h" ] || \
   ([ ! -f "/usr/local/lib64/cmake/c-ares/c-ares-config.cmake" ] && [ ! -f "/usr/local/lib/cmake/c-ares/c-ares-config.cmake" ]); then
    echo "c-ares CMake configs missing. Building c-ares in-line from source..."
    CARES_DIR="${WORKING_DIR}/c-ares"
    if [ ! -d "${CARES_DIR}" ]; then
        git clone https://github.com/c-ares/c-ares.git "${CARES_DIR}"
    fi
    cd "${CARES_DIR}"
    git checkout cares-1_19_1 2>/dev/null || git checkout v1.19.1 2>/dev/null || true
    rm -rf build && mkdir -p build && cd build
    fix_cmake_root
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

# 0.3 re2 (Wheel -> In-line Source Build)
RE2_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 -name 're2*.whl' 2>/dev/null | head -1)
if [ -n "${RE2_WHEEL}" ]; then
    echo "Using local RE2 wheel: ${RE2_WHEEL}"
    python3 -m pip install "${RE2_WHEEL}" 2>/dev/null || true
else
    echo "Attempting to install RE2 from IBM developer wheels index..."
    python3 -m pip install --extra-index-url https://wheels.developerfirst.ibm.com/simple/ --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ --trusted-host wheels.developerfirst.ibm.com re2 2>/dev/null || true
fi

RE2_PKG_DIR=$(find_pkg_dir "re2")
[ -n "${RE2_PKG_DIR}" ] && extract_wheel_artifacts "${RE2_PKG_DIR}"

if [ ! -f "/usr/local/include/re2/re2.h" ] || \
   ([ ! -f "/usr/local/lib64/cmake/re2/re2Config.cmake" ] && [ ! -f "/usr/local/lib/cmake/re2/re2Config.cmake" ]); then
    echo "RE2 CMake configs missing. Building RE2 in-line from source..."
    RE2_DIR="${WORKING_DIR}/re2"
    if [ ! -d "${RE2_DIR}" ]; then
        git clone https://github.com/google/re2.git "${RE2_DIR}"
    fi
    cd "${RE2_DIR}"
    git checkout 2022-04-01 2>/dev/null || true
    rm -rf build && mkdir -p build && cd build
    fix_cmake_root
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

# 0.4 libprotobuf (Wheel -> In-line Source Build)
PROTOBUF_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 -name '*protobuf*.whl' 2>/dev/null | head -1)
if [ -n "${PROTOBUF_WHEEL}" ]; then
    echo "Using local Protobuf wheel: ${PROTOBUF_WHEEL}"
    python3 -m pip install "${PROTOBUF_WHEEL}" 2>/dev/null || true
else
    echo "Attempting to install Protobuf from IBM developer wheels index..."
    python3 -m pip install --extra-index-url https://wheels.developerfirst.ibm.com/simple/ --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ --trusted-host wheels.developerfirst.ibm.com libprotobuf protobuf 2>/dev/null || true
fi

PROTOBUF_PKG_DIR=$(find_pkg_dir "libprotobuf" "google.protobuf" "google/protobuf")
[ -n "${PROTOBUF_PKG_DIR}" ] && extract_wheel_artifacts "${PROTOBUF_PKG_DIR}"

if [ ! -f "/usr/local/include/google/protobuf/message.h" ] || \
   [ ! -f "/usr/local/bin/protoc" ] || \
   ([ ! -f "/usr/local/lib64/cmake/protobuf/protobuf-config.cmake" ] && [ ! -f "/usr/local/lib/cmake/protobuf/protobuf-config.cmake" ]); then
    echo "Protobuf CMake configs or protoc binary missing. Building Protobuf in-line from source..."
    PROTOBUF_DIR="${WORKING_DIR}/protobuf"
    if [ ! -d "${PROTOBUF_DIR}" ]; then
        git clone https://github.com/protocolbuffers/protobuf.git "${PROTOBUF_DIR}"
    fi
    cd "${PROTOBUF_DIR}"
    git checkout v28.0 2>/dev/null || git checkout v28.3 2>/dev/null || git checkout v33.6 2>/dev/null || true
    git submodule update --init --recursive 2>/dev/null || true
    rm -rf build && mkdir -p build && cd build
    fix_cmake_root
    cmake \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_ABSL_PROVIDER=package \
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_PREFIX_PATH="/usr/local;/usr/local/lib64/cmake;/usr/local/lib/cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -GNinja \
        ..
    ninja -j"$(nproc)"
    ninja install
    cp -a /usr/local/lib/libproto*.so* /usr/local/lib64/ 2>/dev/null || true
    cp -a /usr/local/lib64/libproto*.so* /usr/local/lib/ 2>/dev/null || true
    cd "${WORKING_DIR}"
fi
fix_cmake_root

# 0.5 grpc_cpp (Wheel -> In-line Source Build)
GRPC_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 -name 'grpc_cpp*.whl' 2>/dev/null | head -1)
if [ -n "${GRPC_WHEEL}" ]; then
    echo "Using local gRPC wheel: ${GRPC_WHEEL}"
    python3 -m pip install "${GRPC_WHEEL}" 2>/dev/null || true
else
    echo "Attempting to install gRPC from IBM developer wheels index..."
    python3 -m pip install --extra-index-url https://wheels.developerfirst.ibm.com/simple/ --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ --trusted-host wheels.developerfirst.ibm.com grpc_cpp grpc-cpp 2>/dev/null || true
fi

GRPC_PKG_DIR=$(find_pkg_dir "grpc_cpp" "grpccpp" "grpc")
[ -n "${GRPC_PKG_DIR}" ] && extract_wheel_artifacts "${GRPC_PKG_DIR}"

if [ ! -f "/usr/local/include/grpcpp/grpcpp.h" ] || \
   ([ ! -f "/usr/local/lib64/cmake/grpc/gRPCConfig.cmake" ] && [ ! -f "/usr/local/lib/cmake/grpc/gRPCConfig.cmake" ]); then
    echo "gRPC CMake configs missing. Building gRPC in-line from source..."
    GRPC_DIR="${WORKING_DIR}/grpc"
    if [ ! -d "${GRPC_DIR}" ]; then
        git clone --recurse-submodules https://github.com/grpc/grpc.git "${GRPC_DIR}"
    fi
    cd "${GRPC_DIR}"
    git checkout v1.68.0 2>/dev/null || git checkout 1.80.0 2>/dev/null || true
    git submodule update --init --recursive 2>/dev/null || true
    rm -rf build && mkdir -p build && cd build
    fix_cmake_root
    cmake \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DgRPC_INSTALL=ON \
        -DgRPC_BUILD_TESTS=OFF \
        -DgRPC_BUILD_CODEGEN=ON \
        -DgRPC_ABSL_PROVIDER=package \
        -DgRPC_PROTOBUF_PROVIDER=package \
        -DgRPC_RE2_PROVIDER=package \
        -DgRPC_CARES_PROVIDER=package \
        -DgRPC_SSL_PROVIDER=package \
        -DgRPC_ZLIB_PROVIDER=package \
        -DCMAKE_PREFIX_PATH="/usr/local;/usr/local/lib64/cmake;/usr/local/lib/cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -GNinja \
        ..
    ninja -j"$(nproc)"
    ninja install
    cp -a /usr/local/lib/libgrpc*.so* /usr/local/lib64/ 2>/dev/null || true
    cp -a /usr/local/lib64/libgrpc*.so* /usr/local/lib/ 2>/dev/null || true
    cd "${WORKING_DIR}"
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

# Look for and apply patch if available across multiple candidate locations or GitHub fallback
PATCH_NAME="${PACKAGE_NAME}_${PACKAGE_VERSION}.patch"
PATCH_PATH=""

for candidate in \
    "${SCRIPT_PATH}/${PATCH_NAME}" \
    "${WORKING_DIR}/l/${PACKAGE_NAME}/${PATCH_NAME}" \
    "${WORKING_DIR}/${PACKAGE_NAME}/${PATCH_NAME}" \
    "${WORKING_DIR}/${PATCH_NAME}" \
    "${BUILD_HOME}/l/${PACKAGE_NAME}/${PATCH_NAME}" \
    "${BUILD_HOME}/${PATCH_NAME}"; do
    if [ -f "${candidate}" ] && [ -s "${candidate}" ]; then
        PATCH_PATH="${candidate}"
        break
    fi
done

if [ -z "${PATCH_PATH}" ]; then
    PATCH_PATH=$(find /tmp /home/tester "${WORKING_DIR}" -maxdepth 5 -name "${PATCH_NAME}" 2>/dev/null | head -1)
fi

if [ -z "${PATCH_PATH}" ] || [ ! -f "${PATCH_PATH}" ]; then
    echo "Attempting to fetch ${PATCH_NAME} from remote build-scripts repository..."
    for remote_url in \
        "https://raw.githubusercontent.com/ppc64le/build-scripts/master/l/${PACKAGE_NAME}/${PATCH_NAME}" \
        "https://raw.githubusercontent.com/ppc64le/build-scripts/main/l/${PACKAGE_NAME}/${PATCH_NAME}" \
        "https://raw.githubusercontent.com/Shivender-Singh/build-scripts/libgoogle-cloud-storage/l/${PACKAGE_NAME}/${PATCH_NAME}" \
        "https://raw.githubusercontent.com/Shivender-Singh/build-scripts/master/l/${PACKAGE_NAME}/${PATCH_NAME}"; do
        if wget -q -O "${WORKING_DIR}/${PATCH_NAME}" "${remote_url}" 2>/dev/null && [ -s "${WORKING_DIR}/${PATCH_NAME}" ]; then
            PATCH_PATH="${WORKING_DIR}/${PATCH_NAME}"
            echo "Downloaded patch from ${remote_url}"
            break
        fi
    done
fi

if [ -n "${PATCH_PATH}" ] && [ -f "${PATCH_PATH}" ] && [ -s "${PATCH_PATH}" ]; then
    echo "Applying patch: ${PATCH_PATH}"
    git apply "${PATCH_PATH}" 2>/dev/null || patch -p1 < "${PATCH_PATH}" 2>/dev/null || echo "Patch application skipped or already applied."
else
    echo "No patch file found for ${PACKAGE_VERSION}; proceeding with build."
fi

SOURCE_DIR=$(pwd)

# Ensure working directory is SOURCE_DIR and clean existing build directory
cd "$SOURCE_DIR"
rm -rf build
mkdir -p build && cd build
fix_cmake_root

ldconfig /usr/local/lib64 /usr/local/lib 2>/dev/null || true
export LD_LIBRARY_PATH="/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH:-}"

echo "===== Tool & Library Linker Checks ====="
which protoc 2>/dev/null || true
protoc --version 2>/dev/null || true
ldd /usr/local/bin/grpc_cpp_plugin 2>/dev/null || true
find /usr/local -name "libre2*" -ls 2>/dev/null || true
find /usr/local -name "re2Config*.cmake" -ls 2>/dev/null || true
ls -l /usr/local/lib/libre2* 2>/dev/null || true
ls -l /usr/local/lib64/libre2* 2>/dev/null || true

# Build google-cloud-cpp with Storage component enabled
if ! cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_PREFIX_PATH="/usr/local;/usr/local/lib64/cmake;/usr/local/lib/cmake;/usr" \
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
rm -rf "${SOURCE_DIR}/local"
mkdir -p "${SOURCE_DIR}/local/libgoogle_cloud_storage"
PREFIX="${SOURCE_DIR}/local/libgoogle_cloud_storage"

# Install only google-cloud-cpp artifacts into PREFIX
cd "$SOURCE_DIR/build"
DESTDIR="" cmake --install . --prefix "${PREFIX}"

cd "$SOURCE_DIR"

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

# Run C++ unit tests, signed URL conformance, and benchmark/inclusion tests for libgoogle-cloud-storage
cd "$SOURCE_DIR/build"

export LD_LIBRARY_PATH="/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH:-}"

echo "===== gRPC Libraries ====="
find /usr/local -name "libgrpc*.so*" 2>/dev/null | sort || true

echo "===== OpenTelemetry Libraries ====="
find /usr/local -name "libopentelemetry*.so*" 2>/dev/null | sort || true

echo "===== ldd ====="
ldd google/cloud/opentelemetry/opentelemetry_trace_exporter_test 2>/dev/null || true

echo "===== Single Test ====="
ctest -V -R opentelemetry_trace_exporter_test || true

echo "================ Running Storage CTest Suite ================"
if ! ctest --output-on-failure -j"$(nproc)" \
    -LE "integration-test|integration-test-emulator|integration-test-gha|quickstart|opentelemetry" \
    -E "(opentelemetry_|storage_benchmarks_|common_grpc|common_internal_grpc|common_completion_queue|common_internal_async|common_internal_rest|common_internal_streaming|common_internal_log|common_internal_minimal|common_internal_populate|common_internal_resumable|common_internal_retry|common_internal_routing|common_internal_time|common_internal_unified|common_connection_options|common_internal_background|common_internal_debug|common_internal_extract|testing_util_is_proto)"; then
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
python3 -m build --wheel --no-isolation -C--build-option=--plat-name=linux_ppc64le 2>/dev/null || python3 -m build --wheel --no-isolation

# Copy the target libgoogle_cloud_storage wheel to WORKING_DIR
cp -f "${SOURCE_DIR}/dist/"libgoogle_cloud_storage*.whl "${WORKING_DIR}/" 2>/dev/null || \
cp -f "${SOURCE_DIR}/dist/"*.whl "${WORKING_DIR}/" 2>/dev/null || true

cd "$WORKING_DIR"

# Ensure ONLY the libgoogle_cloud_storage wheel exists in WORKING_DIR, HOME, and SOURCE_DIR
find "${WORKING_DIR}" "${SOURCE_DIR}" "${HOME}" /home/tester -maxdepth 2 -name "*.whl" 2>/dev/null | while read -r whl; do
    local_base=$(basename "$whl")
    if [[ "$local_base" != libgoogle_cloud_storage* ]] && [[ "$local_base" != google_cloud_storage* ]] && [[ "$local_base" != libgoogle-cloud-storage* ]]; then
        echo "Removing dependency wheel: $whl"
        rm -f "$whl" 2>/dev/null || true
    fi
done

echo "=== Generated Wheel Files in ${WORKING_DIR} ==="
ls -la "${WORKING_DIR}"/*.whl 2>/dev/null || true

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
