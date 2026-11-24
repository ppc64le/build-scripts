#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opentelemetry-cpp
# Version       : v1.27.0
# Source repo   : https://github.com/open-telemetry/opentelemetry-cpp
# Tested on     : UBI:10.2
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivender Singh <shivender.singh2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
#             platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=opentelemetry-cpp
PACKAGE_DIR=opentelemetry-cpp
SCRIPT_PACKAGE_VERSION=v1.27.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/open-telemetry/opentelemetry-cpp
WORKING_DIR=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')

# Test dependency versions
GTEST_VERSION=${GTEST_VERSION:-v1.14.0}
BENCHMARK_VERSION=${BENCHMARK_VERSION:-v1.9.4}

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected - no arch-specific flags applied"
fi

yum install -y git gcc-c++ gcc wget make python3 python3-pip yum-utils apr-devel perl openssl-devel automake autoconf libtool cmake

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

gcc --version
cmake --version
python3 --version

# Install gtest
cd "$WORKING_DIR"
rm -rf googletest
if ! git clone https://github.com/google/googletest.git; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd googletest/
git checkout "$GTEST_VERSION"
mkdir build
cd build
if ! (cmake .. && make -j"$(nproc)" && make install); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Install benchmark
cd "$WORKING_DIR"
rm -rf benchmark
if ! git clone https://github.com/google/benchmark.git; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd benchmark
git checkout "$BENCHMARK_VERSION"
if ! (cmake -E make_directory "build" \
      && cmake -E chdir "build" cmake -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on -DCMAKE_BUILD_TYPE=Release ../ \
      && cmake --build "build" --config Release \
      && cmake --build "build" --config Release --target install); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Clone source
cd "$WORKING_DIR"
rm -rf "$PACKAGE_DIR"
if ! git clone --recursive "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"
SOURCE_DIR=$(pwd)
echo "Resolved commit: $(git rev-parse HEAD)"

# Local prefix used for wheel packaging
PREFIX="${SOURCE_DIR}/local/opentelemetry_cpp"
mkdir -p "$PREFIX"

# Build and install opentelemetry-cpp (API + SDK + ostream/in-memory exporters; OTLP exporters are OFF by default)
# Shared libraries so the tests can be re-run against the libraries from the installed wheel;
# $ORIGIN lets the installed libraries find each other inside the wheel.
# CMAKE_SKIP_BUILD_RPATH: the test binaries must not have the build tree baked in as RPATH,
# otherwise LD_LIBRARY_PATH cannot point them at the wheel libraries.
if ! (cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SKIP_BUILD_RPATH=ON \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DCMAKE_INSTALL_RPATH='$ORIGIN' \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=ON \
      && cmake --build build -j"$(nproc)" \
      && cmake --install build); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test the build: run the upstream unit tests against the libraries from the build directory
BUILD_LIB_PATH=$(find "${SOURCE_DIR}/build" -name '*.so' -printf '%h\n' | sort -u | paste -sd:)
export LD_LIBRARY_PATH="${BUILD_LIB_PATH}"
if ! (cd build && ctest --output-on-failure -j"$(nproc)"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Create __init__.py so setuptools recognises local/opentelemetry_cpp as a Python package
touch "$PREFIX/__init__.py"

# Build Python wheel
python3 -m pip install --upgrade pip setuptools wheel

# Locate pyproject.toml
_PYPROJECT_SRC=""
if [ -f "${SCRIPT_PATH}/pyproject.toml" ]; then
    _PYPROJECT_SRC="${SCRIPT_PATH}/pyproject.toml"
elif [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/o/opentelemetry-cpp/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/o/opentelemetry-cpp/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" pyproject.toml
else
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opentelemetry-cpp/pyproject.toml
fi
sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#v}/g" pyproject.toml

if ! python3 -m pip wheel . --no-build-isolation --no-deps -w dist; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi
cp -f dist/opentelemetry_cpp-*.whl "$WORKING_DIR/"

# Install the wheel into a clean virtual environment (nothing from the install prefix is on its path)
rm -rf "$WORKING_DIR/venv"
python3 -m venv "$WORKING_DIR/venv"
source "$WORKING_DIR/venv/bin/activate"
if ! python3 -m pip install --force-reinstall --no-deps dist/opentelemetry_cpp-*.whl; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Smoke test: the installed wheel is importable and ships the headers, libraries and CMake package config
if ! python3 -c "
import glob, os, opentelemetry_cpp
d = os.path.dirname(opentelemetry_cpp.__file__)
need = ['include/opentelemetry/trace/tracer.h',
        'include/opentelemetry/sdk/trace/tracer_provider.h',
        'lib64/libopentelemetry_trace.so*',
        'lib64/libopentelemetry_common.so*',
        'lib64/cmake/opentelemetry-cpp/opentelemetry-cpp-config.cmake']
missing = [p for p in need if not glob.glob(os.path.join(d, p))]
assert not missing, 'missing from wheel: %s' % missing
print('opentelemetry_cpp import OK:', d)
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Test the wheel: run the same upstream unit tests again, now against the libraries
# from the installed opentelemetry_cpp wheel
WHEEL_LIB_DIR=$(python3 -c "import os, opentelemetry_cpp; print(os.path.dirname(opentelemetry_cpp.__file__))")/lib64
# Wheel first; the build tree stays on the path only for test-only helper libraries
# (e.g. metrics_common_test_utils) that are not shipped in the wheel.
export LD_LIBRARY_PATH="${WHEEL_LIB_DIR}:${BUILD_LIB_PATH}"

# Make sure the rerun really loads the wheel libraries and not the ones in the build tree:
# every libopentelemetry_* that the wheel ships must resolve to the wheel directory
wheel_libs_used() {
    for t in $(find build -type f -name '*_test' -perm -u+x); do
        if ldd "$t" | grep -q "libopentelemetry_"; then
            ldd "$t" | grep "libopentelemetry_"
            while read -r name path; do
                if [ -e "${WHEEL_LIB_DIR}/${name}" ] && [ "$(dirname "$path")" != "${WHEEL_LIB_DIR}" ]; then
                    return 1
                fi
            done < <(ldd "$t" | awk '/libopentelemetry_/ {print $1, $3}')
            return 0
        fi
    done
    return 1
}
if ! wheel_libs_used; then
    echo "Test binaries are not loading libopentelemetry_* from ${WHEEL_LIB_DIR}"
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

if ! (cd build && ctest --output-on-failure -j"$(nproc)"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi
deactivate

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
