#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : libgoogle-cloud
# Version       : v3.6.0
# Source repo   : https://github.com/googleapis/google-cloud-cpp
# Tested on     : UBI 10.2
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivender Singh <shivender.singh2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=libgoogle-cloud
PACKAGE_DIR=google-cloud-cpp
SCRIPT_PACKAGE_VERSION=v3.6.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/googleapis/google-cloud-cpp
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Test dependency versions
JSON_VERSION=${JSON_VERSION:-v3.11.3}
JSON_SCRIPT=json_ubi_10.2.sh
OPENTELEMETRY_CPP_VERSION=${OPENTELEMETRY_CPP_VERSION:-v1.18.0}
OPENTELEMETRY_CPP_SCRIPT=opentelemetry-cpp_ubi_10.2.sh
GTEST_VERSION=${GTEST_VERSION:-v1.15.2}
BENCHMARK_VERSION=${BENCHMARK_VERSION:-v1.9.0}

IBM_WHEELS_ARGS="--only-binary=:all: --index-url https://wheels.developerfirst.ibm.com/simple/ --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ --trusted-host wheels.developerfirst.ibm.com"

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install dependencies
yum install -y --allowerasing \
    wget \
    git \
    cmake \
    make \
    gcc \
    gcc-c++ \
    openssl-devel \
    libcurl-devel \
    zlib-devel \
    python3 \
    python3-pip

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

gcc --version
cmake --version

# Dependencies are IBM Power wheels already, so they are used in place via CMAKE_PREFIX_PATH (no extraction into /usr/local).
# Wheel names are not Python import names, so each wheel's root is located from pip metadata, not by importing.
# libprotobuf is listed first: it bundles the newer Abseil (2505) that protobuf/gRPC were built with, and CMake must find that one.
DEP_WHEELS="libprotobuf grpc_cpp abseil_cpp c_ares re2"
LOCATE_WHEELS='
import os, sys
import importlib.metadata as md
prefixes, libdirs, rpaths = [], [], []
for name in sys.argv[1:]:
    dist = md.distribution(name)
    for f in dist.files:
        i = next((n for n, p in enumerate(f.parts) if p in ("include", "lib", "lib64", "bin")), None)
        if i is not None:
            break
    else:
        sys.exit(name + ": no include/lib files found in wheel")
    base = str(dist.locate_file(""))
    prefix = os.path.normpath(os.path.join(base, *f.parts[:i]))
    prefixes.append(prefix)
    for sub in ("lib64", "lib"):
        d = os.path.join(prefix, sub)
        if os.path.isdir(d):
            libdirs.append(d)
            rpaths.append("$ORIGIN/../../" + os.path.relpath(d, base))
print(";".join(prefixes), ":".join(libdirs), ":".join(rpaths))'

# Download and install the dependency wheels, exit if any is not found
if ! python3 -m pip install --no-deps ${IBM_WHEELS_ARGS} ${DEP_WHEELS} \
   || ! DEP_INFO=$(python3 -c "${LOCATE_WHEELS}" ${DEP_WHEELS}); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi
read -r DEP_PREFIXES DEP_LIBS DEP_RPATH <<< "${DEP_INFO}"
DEP_BINS=$(echo "${DEP_PREFIXES}" | sed 's#;#/bin:#g;s#$#/bin#')
export PATH="${DEP_BINS}:${PATH}"
export LD_LIBRARY_PATH="${DEP_LIBS}:${LD_LIBRARY_PATH:-}"
ldconfig
export CMAKE_PREFIX_PATH="${DEP_PREFIXES};/usr/local;/usr/local/lib64/cmake;/usr/local/lib/cmake;/usr/local/share/cmake"

# Build dependencies that have no wheel: googletest, benchmark
git clone --depth 1 --branch "${GTEST_VERSION}" \
    https://github.com/google/googletest.git

git clone --depth 1 --branch "${BENCHMARK_VERSION}" \
    https://github.com/google/benchmark.git
	
# Build json using existing build script
if wget -q \
    "https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/j/json/${JSON_SCRIPT}"
then
    echo "Building json using ${JSON_SCRIPT}"

    if ! bash "${JSON_SCRIPT}" "${JSON_VERSION}"
    then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
        exit 1
    fi
else
    echo "Failed to download ${JSON_SCRIPT}"
    exit 1
fi

export CMAKE_PREFIX_PATH="/root/json/local/nlohmann_json;${CMAKE_PREFIX_PATH}"
# Build opentelemetry-cpp using existing build script

if wget -q \
    "https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opentelemetry-cpp/${OPENTELEMETRY_CPP_SCRIPT}"
then
    echo "Building opentelemetry-cpp using ${OPENTELEMETRY_CPP_SCRIPT}"

    if ! bash "${OPENTELEMETRY_CPP_SCRIPT}" "${OPENTELEMETRY_CPP_VERSION}"
    then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
        exit 1
    fi
else
    echo "Failed to download ${OPENTELEMETRY_CPP_SCRIPT}"
    exit 1
fi

export CMAKE_PREFIX_PATH="/root/opentelemetry-cpp/build/cmake;${CMAKE_PREFIX_PATH}"
# Clone source
rm -rf "$PACKAGE_DIR"
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"
echo "Resolved commit: $(git rev-parse HEAD)"
SOURCE_DIR=$(pwd)

# Verify the protobuf / gRPC tools and CMake configs from the wheels are discoverable
command -v protoc >/dev/null 2>&1 || {
    echo "ERROR: protoc not found"
    exit 1
}

command -v grpc_cpp_plugin >/dev/null 2>&1 || {
    echo "ERROR: grpc_cpp_plugin not found"
    exit 1
}

protoc --version

echo "===== DEP_PREFIXES ====="
echo "${DEP_PREFIXES}"

echo "===== CMake configs ====="
find $(echo "${DEP_PREFIXES}" | tr ';' ' ') \( -name '*Config.cmake' -o -name '*config.cmake' \) | sort

# Local prefix used for wheel packaging
mkdir -p local/libgoogle_cloud
PREFIX="${SOURCE_DIR}/local/libgoogle_cloud"

echo "===== CMAKE_PREFIX_PATH ====="
echo "${CMAKE_PREFIX_PATH}"

find /root/json -name "nlohmann_jsonConfig.cmake" 2>/dev/null
find /root/opentelemetry-cpp \( -name "*opentelemetry*Config.cmake" -o -name "*opentelemetry*config.cmake" \)

echo "===== VERIFY JSON ====="
find /root/json/local/nlohmann_json -name "nlohmann_jsonConfig.cmake"

echo "===== VERIFY OTEL ====="
find /root/opentelemetry-cpp -name "opentelemetry-cpp-config.cmake"

# Build and install (default google-cloud-cpp component set)
if ! (cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DCMAKE_INSTALL_RPATH="\$ORIGIN:${DEP_RPATH}" \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=ON \
        -DGOOGLE_CLOUD_CPP_ENABLE_EXAMPLES=OFF \
        -DGOOGLE_CLOUD_CPP_ENABLE_WERROR=OFF \
		-DGOOGLE_CLOUD_CPP_ENABLE_GRPC=ON \
        -DGOOGLE_CLOUD_CPP_ENABLE_REST=ON \
        -DGOOGLE_CLOUD_CPP_ENABLE="__common__" \
      && cmake --build build -j"$(nproc)" \
      && cmake --install build); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test the build (skip integration / emulator / benchmark tests that need network or credentials)
export LD_LIBRARY_PATH="${PREFIX}/lib64:${LD_LIBRARY_PATH}"

if ! (cd build && ctest --output-on-failure -j"$(nproc)" \
        -LE "integration-test|integration-test-emulator|integration-test-gha|quickstart" \
        -E "integration|emulator|benchmark|samples|quickstart"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Create __init__.py so setuptools recognises local/libgoogle_cloud as a Python package
touch local/libgoogle_cloud/__init__.py

# Build Python wheel
python3 -m pip install --upgrade setuptools wheel

# Locate pyproject.toml — try two known repo-relative paths before wget:
_PYPROJECT_SRC=""
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/l/libgoogle-cloud/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/l/libgoogle-cloud/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" pyproject.toml
else
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/l/libgoogle-cloud/pyproject.toml
fi
sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#v}/g" pyproject.toml

if ! python3 -m pip wheel . --no-build-isolation --no-deps -w dist; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi
cp dist/libgoogle_cloud-*.whl "${WORKING_DIR}/"

# Install the wheel (and its dependency wheels) into a clean venv
python3 -m venv "${WORKING_DIR}/venv"
if ! "${WORKING_DIR}/venv/bin/python" -m pip install ${IBM_WHEELS_ARGS} dist/libgoogle_cloud-*.whl; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

# Smoke test: the installed wheel is importable and ships the shared libraries
if ! "${WORKING_DIR}/venv/bin/python" -c "import os, glob, libgoogle_cloud; d = os.path.dirname(libgoogle_cloud.__file__); assert glob.glob(os.path.join(d, 'lib64', 'libgoogle_cloud_cpp_common.so*')); assert os.path.isfile(os.path.join(d, 'include', 'google', 'cloud', 'version.h')); print('libgoogle_cloud import OK')"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Test the wheel: run the same upstream tests again, now against the libraries from the venv-installed wheels
cd "$SOURCE_DIR"
VENV_INFO=$("${WORKING_DIR}/venv/bin/python" -c "${LOCATE_WHEELS}" libgoogle-cloud ${DEP_WHEELS})
read -r _ VENV_LIBS _ <<< "${VENV_INFO}"
export LD_LIBRARY_PATH="${VENV_LIBS}:${LD_LIBRARY_PATH:-}"
if ! (cd build && ctest --output-on-failure -j"$(nproc)" \
        -LE "integration-test|integration-test-emulator|integration-test-gha|quickstart" \
        -E "integration|emulator|benchmark|samples|quickstart"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
