#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : json
# Version       : v3.12.0
# Source repo   : https://github.com/nlohmann/json
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

PACKAGE_NAME=json
PACKAGE_DIR=json
SCRIPT_PACKAGE_VERSION=v3.12.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/nlohmann/json
WORKING_DIR=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected - no arch-specific flags applied"
fi

yum install -y git gcc-c++ gcc wget make python3 python3-pip cmake diffutils

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

gcc --version
cmake --version
python3 --version

# Clone source
cd "$WORKING_DIR"
rm -rf "$PACKAGE_DIR"
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
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
PREFIX="${SOURCE_DIR}/local/nlohmann_json"
mkdir -p "$PREFIX"

# Build with unit tests and install into the local prefix (tests download json_test_data from GitHub)
if ! (cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DJSON_BuildTests=ON \
        -DJSON_Install=ON \
      && cmake --build build -j"$(nproc)" \
      && cmake --install build); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test the build: run the upstream unit tests
if ! (cd build && ctest --output-on-failure -j"$(nproc)"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Create __init__.py so setuptools recognises local/nlohmann_json as a Python package
touch "$PREFIX/__init__.py"

# Build Python wheel
python3 -m pip install --upgrade pip setuptools wheel

# Locate pyproject.toml
_PYPROJECT_SRC=""
if [ -f "${SCRIPT_PATH}/pyproject.toml" ]; then
    _PYPROJECT_SRC="${SCRIPT_PATH}/pyproject.toml"
elif [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/j/json/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/j/json/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" pyproject.toml
else
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/j/json/pyproject.toml
fi
sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#v}/g" pyproject.toml

if ! python3 -m pip wheel . --no-build-isolation --no-deps -w dist; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi
cp -f dist/nlohmann_json-*.whl "$WORKING_DIR/"

# Install the wheel into a clean virtual environment (nothing from the install prefix is on its path)
rm -rf "$WORKING_DIR/venv"
python3 -m venv "$WORKING_DIR/venv"
source "$WORKING_DIR/venv/bin/activate"
if ! python3 -m pip install --force-reinstall --no-deps dist/nlohmann_json-*.whl; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Smoke test: the installed wheel is importable and ships the headers, CMake package config and pkg-config file
if ! python3 -c "
import glob, os, nlohmann_json
d = os.path.dirname(nlohmann_json.__file__)
need = ['include/nlohmann/json.hpp',
        'include/nlohmann/json_fwd.hpp',
        'share/cmake/nlohmann_json/nlohmann_jsonConfig.cmake',
        'share/pkgconfig/nlohmann_json.pc']
missing = [p for p in need if not glob.glob(os.path.join(d, p))]
assert not missing, 'missing from wheel: %s' % missing
print('nlohmann_json import OK:', d)
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Test the wheel: its headers must match the source tree headers
WHEEL_INCLUDE_DIR=$(python3 -c "import os, nlohmann_json; print(os.path.dirname(nlohmann_json.__file__))")/include/nlohmann
if ! diff -r "${SOURCE_DIR}/include/nlohmann" "${WHEEL_INCLUDE_DIR}"; then
    echo "Headers in the installed wheel differ from include/nlohmann"
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
