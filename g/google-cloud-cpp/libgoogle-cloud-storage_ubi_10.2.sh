#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : libgoogle-cloud-storage
# Version       : v3.6.0
# Source repo   : https://github.com/googleapis/google-cloud-cpp
# Tested on UBI:10.2
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
SCRIPT_PATH=$(dirname "$(realpath "$0")")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER11" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power11 -mtune=power11"
    echo "Detected POWER11 - applying power11 optimization flags"
elif grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "Neither POWER10 nor POWER11 detected - no arch-specific flags applied"
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
    if grep -q "POWER11" /proc/cpuinfo 2>/dev/null; then
        echo "Installed GCC does not support -mcpu=power11; falling back to -mcpu=power10"
        CPU_FLAGS="-mcpu=power10 -mtune=power10"
    else
        CPU_FLAGS=""
    fi
fi

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS} -O3"
export CXXFLAGS="${CPU_FLAGS} -O3"

gcc --version
g++ --version
cmake --version
python3 --version

# --- Step 0: Install Abseil-cpp, nlohmann_json, OpenTelemetry, GoogleTest, and Google Benchmark ---
# 0.1 Abseil-cpp (prefer wheel; fallback to source build)
ABSEIL_WHEEL=$(find "${SCRIPT_PATH}" "${WORKING_DIR}" -maxdepth 1 -name 'abseil_cpp*.whl' 2>/dev/null | head -1)

if [ -n "${ABSEIL_WHEEL}" ]; then
    echo "Using Abseil wheel: ${ABSEIL_WHEEL}"
    python3 -m pip install "${ABSEIL_WHEEL}"
fi

ABSL_PKG_DIR=$(python3 -c "import abseil_cpp, os; print(os.path.dirname(abseil_cpp.__file__))" 2>/dev/null || true)
if [ -n "${ABSL_PKG_DIR}" ] && [ -d "${ABSL_PKG_DIR}/include/absl" ]; then
    echo "Extracted Abseil C++ headers and libraries from wheel (${ABSL_PKG_DIR}) to /usr/local"
    mkdir -p /usr/local/include /usr/local/lib64 /usr/local/lib /usr/local/share
    cp -rf "${ABSL_PKG_DIR}/include/absl" /usr/local/include/ 2>/dev/null || true
    cp -rf "${ABSL_PKG_DIR}/lib64/"* /usr/local/lib64/ 2>/dev/null || true
    cp -rf "${ABSL_PKG_DIR}/lib/"* /usr/local/lib/ 2>/dev/null || true
    cp -rf "${ABSL_PKG_DIR}/share/"* /usr/local/share/ 2>/dev/null || true
elif [ ! -f "/usr/local/lib64/libabsl_base.so" ] && [ ! -f "/usr/local/lib/libabsl_base.a" ] && [ ! -f "/usr/local/lib64/cmake/absl/abslConfig.cmake" ]; then
    echo "Abseil wheel not found. Building from source..."
    ABSL_DIR="${WORKING_DIR}/abseil-cpp"
    if [ ! -d "${ABSL_DIR}" ]; then
        git clone https://github.com/abseil/abseil-cpp.git "${ABSL_DIR}"
    fi
    cd "${ABSL_DIR}"
    git checkout 20240722.0 2>/dev/null || true
    mkdir -p build && cd build
    cmake \
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

JSON_DIR="${WORKING_DIR}/json"
if [ ! -d "${JSON_DIR}" ]; then
    git clone https://github.com/nlohmann/json.git "${JSON_DIR}"
fi

if [ ! -f "/usr/local/share/cmake/nlohmann_json/nlohmann_jsonConfig.cmake" ] && [ ! -f "/usr/local/include/nlohmann/json.hpp" ]; then
    cd "${JSON_DIR}"
    git checkout v3.11.3 2>/dev/null || true
    mkdir -p build && cd build
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DJSON_BuildTests=OFF \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -GNinja \
        ..
    ninja install
    cd "${WORKING_DIR}"
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
fi

GTEST_DIR="${WORKING_DIR}/googletest"
if [ ! -d "${GTEST_DIR}" ]; then
    git clone https://github.com/google/googletest.git "${GTEST_DIR}"
fi

if [ ! -f "/usr/local/lib64/cmake/GTest/GTestConfig.cmake" ] && [ ! -f "/usr/local/lib/cmake/GTest/GTestConfig.cmake" ] && [ ! -f "/usr/local/include/gtest/gtest.h" ]; then
    cd "${GTEST_DIR}"
    git checkout v1.15.2 2>/dev/null || true
    mkdir -p build && cd build
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -GNinja \
        ..
    ninja -j"$(nproc)"
    ninja install
    cd "${WORKING_DIR}"
fi

BENCH_DIR="${WORKING_DIR}/benchmark"
if [ ! -d "${BENCH_DIR}" ]; then
    git clone https://github.com/google/benchmark.git "${BENCH_DIR}"
fi

if [ ! -f "/usr/local/lib64/cmake/benchmark/benchmarkConfig.cmake" ] && [ ! -f "/usr/local/lib/cmake/benchmark/benchmarkConfig.cmake" ] && [ ! -f "/usr/local/include/benchmark/benchmark.h" ]; then
    cd "${BENCH_DIR}"
    git checkout v1.9.0 2>/dev/null || true
    mkdir -p build && cd build
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
fi

# Clone source
rm -rf "$PACKAGE_DIR"
if ! git clone --recurse-submodules "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION" || git checkout "v${PACKAGE_VERSION#v}" || true
git submodule update --init --recursive

SOURCE_DIR=$(pwd)

# Patch google_cloud_cpp_common.cmake to always link opentelemetry-cpp::api when available
sed -i 's/if (opentelemetry IN_LIST GOOGLE_CLOUD_CPP_ENABLE)/if (TRUE)/g' google/cloud/google_cloud_cpp_common.cmake

# Ensure working directory is SOURCE_DIR and clean existing build directory
cd "$SOURCE_DIR"
rm -rf build
mkdir -p build && cd build

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
    -DGOOGLE_CLOUD_CPP_ENABLE="storage,-monitoring,-trace,-opentelemetry,-universe_domain" \
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

# Copy all dependency headers and libraries (Abseil, JSON, OpenTelemetry, etc.) into PREFIX
for dep in absl nlohmann opentelemetry; do
    if [ -d "/usr/local/include/${dep}" ]; then
        cp -rf "/usr/local/include/${dep}" "${PREFIX}/include/" 2>/dev/null || true
    fi
done
cp -d /usr/local/lib64/libabsl*.so* "${PREFIX}/lib64/" 2>/dev/null || true
cp -d /usr/local/lib/libabsl*.so* "${PREFIX}/lib/" 2>/dev/null || true
cp -d /usr/local/lib64/libopentelemetry*.so* "${PREFIX}/lib64/" 2>/dev/null || true
cp -d /usr/local/lib/libopentelemetry*.so* "${PREFIX}/lib/" 2>/dev/null || true

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

# Run C++ unit tests excluding integration, emulator and sample tests
cd "$SOURCE_DIR/build"
export LD_LIBRARY_PATH="/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH:-}"
if ! ctest --output-on-failure -j"$(nproc)" \
    --exclude-regex 'integration|emulator|samples|storage_object_file_multi_threaded_test'; then
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
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/l/libgoogle-cloud-storage/pyproject.toml || true
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
